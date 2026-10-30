import Foundation
import Supabase

/// Reads and writes the MCRI Connect tables. Every payload type below declares its own
/// `CodingKeys` in column form because the PostgREST coder does not convert key case:
/// a property named `fullName` would otherwise be sent as `fullName` and rejected.
final class SupabaseDataService: DataService {
    private let client: SupabaseClient

    init(client: SupabaseClient = supabase) {
        self.client = client
    }

    private var currentProfileID: UUID? { client.auth.currentSession?.user.id }

    // MARK: Reads

    func profile(for session: Session) async throws -> ProfileRecord? {
        guard let id = session.id else { throw DataError.notSignedIn }
        let rows: [ProfileDTO] = try await client.from("profiles")
            .select("id, role, full_name, email, company_id, avatar_path, status")
            .eq("id", value: id.uuidString)
            .limit(1)
            .execute()
            .value
        return rows.first.map(\.domain)
    }

    func snapshot(session: Session) async throws -> DataSnapshot {
        guard session.isAuthenticated, let id = session.id else { throw DataError.notSignedIn }

        var snapshot = DataSnapshot()
        snapshot.profile = try await profile(for: session)

        // Row Level Security decides what actually comes back; asking for a collection a
        // role has no claim on simply returns the rows it may see.
        switch session.role {
        case .programManager:
            snapshot.students = try await students()
            snapshot.companies = try await companies()
            snapshot.internships = try await internships()
            snapshot.placements = try await placements()
            snapshot.applications = try await applications(studentID: nil)
        case .employer:
            snapshot.companies = try await companies()
            snapshot.internships = try await internships()
            snapshot.candidates = try await candidates()
            snapshot.applications = try await applications(studentID: nil)
        case .student:
            // RLS admits only their own row here, which is what ProfileView edits.
            snapshot.students = try await students()
            snapshot.internships = try await internships()
            snapshot.companies = try await companies()
            snapshot.applications = try await applications(studentID: id)
            snapshot.savedSearches = try await savedSearches()
            snapshot.savedRoleIDs = try await savedRoleIDs(studentID: id)
        }

        snapshot.threads = try await threads()
        return snapshot
    }

    private func students() async throws -> [Student] {
        let rows: [StudentRecordDTO] = try await client.from("student_records")
            .select()
            .order("full_name")
            .execute()
            .value
        return rows.map(\.domain)
    }

    private func companies() async throws -> [Company] {
        let rows: [CompanyRecordDTO] = try await client.from("company_records")
            .select()
            .order("name")
            .execute()
            .value
        return rows.map(\.domain)
    }

    /// Students only ever see live roles from companies a manager has verified.
    private func internships() async throws -> [Internship] {
        let rows: [RoleRecordDTO] = try await client.from("role_records")
            .select()
            .order("posted_date", ascending: false)
            .execute()
            .value
        return rows.map(\.domain)
    }

    private func applications(studentID: UUID?) async throws -> [Application] {
        var query = client.from("application_records").select()
        if let studentID {
            query = query.eq("student_id", value: studentID.uuidString)
        }
        let rows: [ApplicationRecordDTO] = try await query
            .order("last_update_date", ascending: false)
            .execute()
            .value
        return rows.map(\.domain)
    }

    /// The hiring pipeline as one row per live application. Fit scores are calculated on
    /// device by `AppStore.rankCandidates`, so the ranking a recruiter sees is the same
    /// engine the student sees on their own screen.
    private func candidates() async throws -> [Candidate] {
        let rows: [CandidateRecordDTO] = try await client.from("candidate_records")
            .select()
            .execute()
            .value

        return rows.compactMap { row in
            guard let applicationID = UUID(uuidString: row.application_id),
                  let internshipID = UUID(uuidString: row.internship_id),
                  let studentID = UUID(uuidString: row.student_id) else { return nil }
            let student = row.student(id: studentID)
            return Candidate(
                id: applicationID,
                internshipID: internshipID,
                student: student,
                match: 0,
                status: ApplicationStage(rawValue: row.stage) ?? .submitted,
                evidence: student.skills.first(where: { $0.evidence?.isEmpty == false })?.evidence
                    ?? student.bio,
                availableFrom: student.availability.rawValue
            )
        }
    }

    private func placements() async throws -> [Placement] {
        let rows: [PlacementRecordDTO] = try await client.from("placement_records")
            .select()
            .execute()
            .value
        return rows.map(\.domain)
    }

    private func threads() async throws -> [MessageThread] {
        let rows: [ConversationRecordDTO] = try await client.from("conversation_records")
            .select()
            .execute()
            .value
        return rows.map(\.domain)
    }

    private func savedSearches() async throws -> [SavedSearch] {
        let rows: [SavedSearchDTO] = try await client.from("saved_searches")
            .select()
            .order("created_at", ascending: false)
            .execute()
            .value
        return rows.map(\.domain)
    }

    private func savedRoleIDs(studentID: UUID) async throws -> Set<UUID> {
        let rows: [SavedRoleDTO] = try await client.from("saved_roles")
            .select("internship_id")
            .eq("student_id", value: studentID.uuidString)
            .execute()
            .value
        return Set(rows.compactMap { UUID(uuidString: $0.internship_id) })
    }

    // MARK: Student writes

    func save(student: Student) async throws {
        try await client.from("students")
            .upsert(StudentColumn(student: student), onConflict: "id")
            .execute()
    }

    func add(skill: StudentSkill, to studentID: UUID) async throws {
        try await client.from("student_skills")
            .upsert(SkillColumn(skill: skill, studentID: studentID), onConflict: "student_id,name")
            .execute()
    }

    func remove(skillID: UUID) async throws {
        try await client.from("student_skills").delete()
            .eq("id", value: skillID.uuidString).execute()
    }

    func add(project: Project, to studentID: UUID) async throws {
        try await client.from("projects")
            .insert(ProjectColumn(project: project, studentID: studentID)).execute()
    }

    func replace(interests: [String], for studentID: UUID) async throws {
        try await client.from("student_interests").delete()
            .eq("student_id", value: studentID.uuidString).execute()
        guard !interests.isEmpty else { return }
        try await client.from("student_interests")
            .insert(interests.map { InterestColumn(studentID: studentID, interest: $0) })
            .execute()
    }

    func save(search: SavedSearch, studentID: UUID) async throws {
        try await client.from("saved_searches")
            .upsert(SavedSearchColumn(search: search, studentID: studentID),
                    onConflict: "student_id,label")
            .execute()
    }

    func remove(searchID: UUID) async throws {
        try await client.from("saved_searches").delete()
            .eq("id", value: searchID.uuidString).execute()
    }

    func save(application: Application) async throws {
        let rows: [IDDTO] = try await client.from("applications")
            .insert(ApplicationColumn(application: application), returning: .representation)
            .select("id")
            .execute()
            .value
        guard let inserted = rows.first.flatMap({ UUID(uuidString: $0.id) }) else { return }
        for event in application.timeline.prefix(1) {
            try await client.from("application_events")
                .insert(EventColumn(applicationID: inserted, event: event)).execute()
        }
    }

    func withdraw(applicationID: UUID) async throws {
        try await client.rpc("student_withdraw",
                             params: ["p_application_id": applicationID.uuidString]).execute()
    }

    func record(stage: ApplicationStage, on applicationID: UUID, title: String,
                detail: String?) async throws {
        let patch: [String: AnyJSON] = [
            "stage": .string(stage.rawValue),
            "last_update_date": .string(Date().supabaseTimestamp),
        ]
        try await client.from("applications").update(patch)
            .eq("id", value: applicationID.uuidString).execute()
        try await client.from("application_events")
            .insert(EventColumn(applicationID: applicationID,
                                event: TimelineEvent(title: title, detail: detail, date: Date())))
            .execute()
    }

    func setSaved(_ internshipID: UUID, saved: Bool, studentID: UUID) async throws {
        if saved {
            try await client.from("saved_roles")
                .upsert(SavedRoleColumn(studentID: studentID, internshipID: internshipID),
                        onConflict: "student_id,internship_id")
                .execute()
        } else {
            try await client.from("saved_roles").delete()
                .eq("student_id", value: studentID.uuidString)
                .eq("internship_id", value: internshipID.uuidString)
                .execute()
        }
    }

    // MARK: Hiring writes

    func save(internship: Internship, by companyID: UUID) async throws {
        try await client.from("internships")
            .upsert(InternshipColumn(internship: internship, companyID: companyID), onConflict: "id")
            .execute()
    }

    func remove(internshipID: UUID) async throws {
        try await client.from("internships").delete()
            .eq("id", value: internshipID.uuidString).execute()
    }

    func save(company: Company) async throws {
        try await client.from("companies").upsert(CompanyColumn(company: company), onConflict: "id")
            .execute()
    }

    func verify(companyID: UUID, verified: Bool) async throws {
        try await client.rpc("admin_verify_company",
                             params: ["p_company_id": AnyJSON.string(companyID.uuidString),
                                      "p_verified": .bool(verified)])
            .execute()
    }

    // MARK: Programme manager

    func save(placement: Placement) async throws {
        try await client.from("placements")
            .upsert(PlacementColumn(placement: placement), onConflict: "student_id")
            .execute()
    }

    // MARK: Messaging

    func openThread(peerID: UUID, subject: String, context: String,
                    greeting: String) async throws -> UUID {
        let ids: [String] = try await client.rpc("open_thread", params: [
            "p_peer_id": peerID.uuidString,
            "p_subject": subject,
            "p_context": context,
            "p_greeting": greeting,
        ]).execute().value
        guard let id = ids.first.flatMap(UUID.init) else { throw DataError.notFound }
        return id
    }

    func send(message: Message) async throws {
        guard let senderID = currentProfileID else { throw DataError.notSignedIn }
        try await client.from("messages")
            .insert(MessageColumn(message: message, senderID: senderID)).execute()
    }

    func markRead(threadID: UUID) async throws {
        guard let id = currentProfileID else { throw DataError.notSignedIn }
        let patch: [String: AnyJSON] = [
            "unread": .integer(0),
            "last_read": .string(Date().supabaseTimestamp),
        ]
        try await client.from("thread_participants").update(patch)
            .eq("thread_id", value: threadID.uuidString)
            .eq("profile_id", value: id.uuidString)
            .execute()
    }

    // MARK: Files

    func uploadAvatar(_ data: Data, extent: String) async throws -> String {
        guard let id = currentProfileID else { throw DataError.notSignedIn }
        let path = "\(id.uuidString)/avatar.\(extent)"
        try await client.storage.from("avatars")
            .upload(path, data: data, options: FileOptions(upsert: true))
        return path
    }

    func uploadLogo(_ data: Data, companyID: UUID, extent: String) async throws -> String {
        let path = "\(companyID.uuidString)/logo.\(extent)"
        try await client.storage.from("logos")
            .upload(path, data: data, options: FileOptions(upsert: true))
        return path
    }

    func upload(cv data: Data, fileName: String) async throws -> String {
        guard let id = currentProfileID else { throw DataError.notSignedIn }
        let safe = fileName.replacingOccurrences(of: "[^A-Za-z0-9._-]", with: "-",
                                                 options: .regularExpression)
        let path = "\(id.uuidString)/\(safe)"
        try await client.storage.from("cvs")
            .upload(path, data: data, options: FileOptions(upsert: true))
        return path
    }

    /// Public buckets serve images straight to `AsyncImage`; the cv bucket is private and
    /// has no public URL by design, so it is downloaded through the authenticated client.
    func downloadCV(path: String) async throws -> Data {
        try await client.storage.from("cvs").download(path: path)
    }

    // MARK: Account

    func deleteAccount() async throws {
        try await client.rpc("delete_my_account").execute()
    }
}

extension Date {
    /// PostgREST accepts ISO-8601 with fractional seconds for timestamptz columns.
    var supabaseTimestamp: String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.string(from: self)
    }
}
