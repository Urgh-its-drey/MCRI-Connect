import Foundation

/// Everything one workspace needs, gathered in a single round trip. Row Level Security has
/// already trimmed these to what the signed-in role may see, so a student's snapshot simply
/// has no other students in it.
struct DataSnapshot {
    var students: [Student] = []
    var companies: [Company] = []
    var internships: [Internship] = []
    var applications: [Application] = []
    var placements: [Placement] = []
    var threads: [MessageThread] = []
    var savedSearches: [SavedSearch] = []
    var savedRoleIDs: Set<UUID> = []
    var candidates: [Candidate] = []
    var profile: ProfileRecord?
}

/// The account row the app reads its own identity from — never from user metadata.
struct ProfileRecord: Hashable {
    var id: UUID
    var role: UserRole
    var fullName: String
    var email: String?
    var companyID: UUID?
    var avatarPath: String?
    var status: String
}

/// Every read and write the app performs. Two implementations exist: the Supabase one used
/// at runtime and a local one that keeps previews and tests deterministic.
protocol DataService {
    func snapshot(session: Session) async throws -> DataSnapshot
    func profile(for session: Session) async throws -> ProfileRecord?

    // Student-owned records
    func save(student: Student) async throws
    func add(skill: StudentSkill, to studentID: UUID) async throws
    func remove(skillID: UUID) async throws
    func add(project: Project, to studentID: UUID) async throws
    func replace(interests: [String], for studentID: UUID) async throws
    func save(search: SavedSearch, studentID: UUID) async throws
    func remove(searchID: UUID) async throws
    func save(application: Application) async throws
    func withdraw(applicationID: UUID) async throws
    func record(stage: ApplicationStage, on applicationID: UUID, title: String, detail: String?) async throws
    func setSaved(_ internshipID: UUID, saved: Bool, studentID: UUID) async throws

    // Hiring side
    func save(internship: Internship, by companyID: UUID) async throws
    func remove(internshipID: UUID) async throws
    func save(company: Company) async throws
    func verify(companyID: UUID, verified: Bool) async throws

    // Programme manager
    func save(placement: Placement) async throws

    // Messaging
    func openThread(peerID: UUID, subject: String, context: String, greeting: String) async throws -> UUID
    func send(message: Message) async throws
    func markRead(threadID: UUID) async throws

    // Files
    func uploadAvatar(_ data: Data, extent: String) async throws -> String
    func uploadLogo(_ data: Data, companyID: UUID, extent: String) async throws -> String
    func upload(cv data: Data, fileName: String) async throws -> String

    // Account
    func deleteAccount() async throws
}

enum DataError: LocalizedError {
    case offline
    case notFound
    case notSignedIn
    case schemaMissing

    var errorDescription: String? {
        switch self {
        case .offline: return "You are offline. Connect to load fresh data."
        case .notFound: return "We could not find that record."
        case .notSignedIn: return "Sign in again to continue."
        case .schemaMissing: return """
            The MCRI Connect tables are not in this Supabase project yet. Run \
            supabase/schema.sql in the dashboard, then pull to refresh.
            """
        }
    }
}

/// Bundled sample data. Used by previews and by nothing that talks to a live account.
struct LocalDataService: DataService {
    var latency: TimeInterval = 0.35
    var snapshotValue: DataSnapshot

    init(latency: TimeInterval = 0.35, snapshotValue: DataSnapshot = SampleData.snapshot()) {
        self.latency = latency
        self.snapshotValue = snapshotValue
    }

    private func delay() async throws {
        if latency > 0 { try? await Task.sleep(nanoseconds: UInt64(latency * 1_000_000_000)) }
    }

    func snapshot(session: Session) async throws -> DataSnapshot {
        try await delay()
        return snapshotValue
    }

    func profile(for session: Session) async throws -> ProfileRecord? {
        try await delay()
        guard let id = session.id else { return nil }
        return ProfileRecord(id: id, role: session.role, fullName: session.displayName,
                             email: session.email, companyID: session.companyID,
                             avatarPath: session.avatarPath, status: "active")
    }

    func save(student: Student) async throws { try await delay() }
    func add(skill: StudentSkill, to studentID: UUID) async throws { try await delay() }
    func remove(skillID: UUID) async throws { try await delay() }
    func add(project: Project, to studentID: UUID) async throws { try await delay() }
    func replace(interests: [String], for studentID: UUID) async throws { try await delay() }
    func save(search: SavedSearch, studentID: UUID) async throws { try await delay() }
    func remove(searchID: UUID) async throws { try await delay() }
    func save(application: Application) async throws { try await delay() }
    func withdraw(applicationID: UUID) async throws { try await delay() }
    func record(stage: ApplicationStage, on applicationID: UUID, title: String, detail: String?) async throws {
        try await delay()
    }
    func setSaved(_ internshipID: UUID, saved: Bool, studentID: UUID) async throws { try await delay() }
    func save(internship: Internship, by companyID: UUID) async throws { try await delay() }
    func remove(internshipID: UUID) async throws { try await delay() }
    func save(company: Company) async throws { try await delay() }
    func verify(companyID: UUID, verified: Bool) async throws { try await delay() }
    func save(placement: Placement) async throws { try await delay() }

    func openThread(peerID: UUID, subject: String, context: String, greeting: String) async throws -> UUID {
        try await delay()
        return UUID()
    }

    func send(message: Message) async throws { try await delay() }
    func markRead(threadID: UUID) async throws { try await delay() }

    func uploadAvatar(_ data: Data, extent: String) async throws -> String {
        try await delay()
        return "local/avatar.\(extent)"
    }

    func uploadLogo(_ data: Data, companyID: UUID, extent: String) async throws -> String {
        try await delay()
        return "local/\(companyID.uuidString)/logo.\(extent)"
    }

    func upload(cv data: Data, fileName: String) async throws -> String {
        try await delay()
        return "local/\(fileName)"
    }

    func deleteAccount() async throws { try await delay() }
}
