import Foundation
import Combine

struct Toast: Identifiable, Equatable {
    let id = UUID()
    var title: String
    var detail: String?
    var kind: Kind

    enum Kind: String {
        case success, info, warning, danger

        var symbol: String {
            switch self {
            case .success: return "checkmark.circle.fill"
            case .info: return "info.circle.fill"
            case .warning: return "exclamationmark.triangle.fill"
            case .danger: return "xmark.octagon.fill"
            }
        }
    }

    static func success(_ title: String, _ detail: String? = nil) -> Toast {
        Toast(title: title, detail: detail, kind: .success)
    }

    static func info(_ title: String, _ detail: String? = nil) -> Toast {
        Toast(title: title, detail: detail, kind: .info)
    }

    static func warning(_ title: String, _ detail: String? = nil) -> Toast {
        Toast(title: title, detail: detail, kind: .warning)
    }

    static func danger(_ title: String, _ detail: String? = nil) -> Toast {
        Toast(title: title, detail: detail, kind: .danger)
    }
}

/// One source of truth for the signed-in person's workspace. Which rows exist here is
/// decided by Row Level Security on the server, so `students` holds the whole cohort for a
/// manager and exactly one row for a student — the same code path serves all three roles.
@MainActor
final class AppStore: ObservableObject {
    static let shared = AppStore(service: SupabaseDataService(), auth: AuthService.shared)

    private var service: DataService
    private let auth: AuthService

    @Published private(set) var isLoading = false
    @Published private(set) var loadError: String?
    @Published private(set) var lastSyncedAt: Date?

    @Published var students: [Student] = []
    @Published var companies: [Company] = []
    @Published var internships: [Internship] = []
    @Published var applications: [Application] = []
    @Published var candidates: [Candidate] = []
    @Published var savedSearches: [SavedSearch] = []
    @Published var threads: [MessageThread] = []
    @Published var placements: [Placement] = []
    @Published var metrics = ProgramMetrics(totalStudents: 0, readyForPlacement: 0,
                                            activeApplications: 0, successfulPlacements: 0,
                                            unmatchedStudents: 0)
    @Published var readiness: [ReadinessSlice] = []
    @Published var weeklyApplications: [Int] = []
    @Published var alerts: [ReportAlert] = []
    @Published var savedInternshipIDs: Set<UUID> = []
    @Published var toast: Toast?
    /// Set from the saved-search list; Explore replays it and clears it.
    @Published var searchToRun: SavedSearch?

    init(service: DataService = LocalDataService(), auth: AuthService = AuthService.shared) {
        self.service = service
        self.auth = auth
    }

    // MARK: Identity

    var session: Session { auth.session }
    var currentStudentID: UUID? { session.role == .student ? session.id : nil }
    var employerCompanyID: UUID? { session.role == .employer ? session.companyID : nil }

    var currentStudent: Student? {
        guard let id = currentStudentID else { return nil }
        return students.first { $0.id == id }
    }

    var currentCompany: Company? {
        guard let id = employerCompanyID else { return nil }
        return companies.first { $0.id == id }
    }

    // MARK: Derived reads

    var studentApplications: [Application] {
        guard let id = currentStudentID else { return [] }
        return applications.filter { $0.studentID == id }
    }

    /// Roles owned by the signed-in employer's company. Empty for anyone else, so a
    /// partially resolved session can never list another organisation's postings.
    var openRoles: [Internship] {
        guard let companyID = employerCompanyID else { return [] }
        return internships.filter { $0.companyID == companyID }
    }

    /// Roles a student may browse: live postings from companies a manager has verified.
    var publishedRoles: [Internship] {
        internships.filter { $0.companyIsVerified && !$0.isClosed }
    }

    var verifiedCompanies: [Company] { companies.filter { $0.isVerified } }
    var pendingCompanies: [Company] { companies.filter { !$0.isVerified } }

    var unreadMessages: Int { threads.reduce(0) { $0 + $1.unread } }

    var activeApplications: Int { studentApplications.filter { !$0.isClosed }.count }

    func internship(for id: UUID) -> Internship? {
        internships.first { $0.id == id }
    }

    func application(for id: UUID) -> Application? {
        applications.first { $0.id == id }
    }

    func candidates(for internshipID: UUID) -> [Candidate] {
        candidates.filter { $0.internshipID == internshipID }
    }

    /// Only the candidates applied to this employer's own roles, best fit first.
    var employerCandidates: [Candidate] {
        let roleIDs = Set(openRoles.map(\.id))
        return candidates.filter { roleIDs.contains($0.internshipID) }.sorted { $0.match > $1.match }
    }

    func student(for id: UUID) -> Student? {
        students.first { $0.id == id }
    }

    func company(for id: UUID) -> Company? {
        companies.first { $0.id == id }
    }

    func placements(in stage: PlacementStage) -> [Placement] {
        placements.filter { $0.stage == stage }.sorted { $0.readiness > $1.readiness }
    }

    func hasApplied(to internshipID: UUID) -> Bool {
        studentApplications.contains { $0.internshipID == internshipID && !$0.isClosed }
    }

    func match(for internship: Internship) -> MatchResult? {
        guard let student = currentStudent else { return nil }
        return MatchEngine.shared.result(for: student, on: internship)
    }

    /// Best-fit open roles, used by the home screen's "start here" row.
    var recommendedRoles: [MatchedRole] {
        guard let student = currentStudent else { return [] }
        let scored = publishedRoles
            .filter { !hasApplied(to: $0.id) }
            .map { MatchedRole(internship: $0, result: MatchEngine.shared.result(for: student, on: $0)) }
        return Array(scored.sorted { $0.score > $1.score }.prefix(4))
    }

    // MARK: Loading

    func load() async {
        guard !isLoading else { return }
        isLoading = true
        loadError = nil
        do {
            try await applySnapshot(try await service.snapshot(session: session))
            isLoading = false
        } catch {
            loadError = error.localizedDescription
            isLoading = false
        }
    }

    /// Re-reads silently after a write, so the screen shows the server's row — with its
    /// real id — rather than the optimistic one the interface drew first.
    private func sync() async {
        guard session.isAuthenticated else { return }
        do {
            try await applySnapshot(try await service.snapshot(session: session))
        } catch {
            notify(Toast.danger("Not saved", error.localizedDescription))
        }
    }

    private func applySnapshot(_ snapshot: DataSnapshot) async throws {
        students = snapshot.students
        companies = snapshot.companies
        internships = snapshot.internships
        applications = snapshot.applications
        placements = snapshot.placements
        threads = snapshot.threads.sorted { ($0.lastMessage?.sentAt ?? .distantPast)
            > ($1.lastMessage?.sentAt ?? .distantPast) }
        savedSearches = snapshot.savedSearches
        savedInternshipIDs = snapshot.savedRoleIDs
        candidates = rank(snapshot.candidates)
        lastSyncedAt = Date()
        deriveRollups()
    }

    /// Fit is calculated on device so a student and the recruiter looking at them agree.
    private func rank(_ incoming: [Candidate]) -> [Candidate] {
        incoming.map { candidate in
            guard let role = internships.first(where: { $0.id == candidate.internshipID }) else {
                return candidate
            }
            var scored = candidate
            scored.match = MatchEngine.shared.result(for: candidate.student, on: role).score
            return scored
        }
        .sorted { $0.match > $1.match }
    }

    private func deriveRollups() {
        metrics = ProgramMetrics(
            totalStudents: students.count,
            readyForPlacement: students.filter { $0.readiness == .readyToApply }.count,
            activeApplications: applications.filter { !$0.isClosed }.count,
            successfulPlacements: placements.filter { $0.stage == .placed }.count,
            unmatchedStudents: students.filter { student in
                !applications.contains { $0.studentID == student.id && !$0.isClosed }
            }.count
        )

        readiness = ReadinessBand.allCases.map { band in
            ReadinessSlice(band: band, count: students.filter { $0.readiness == band }.count)
        }

        let calendar = Calendar.current
        weeklyApplications = (0..<7).reversed().map { offset in
            guard let day = calendar.date(byAdding: .day, value: -offset, to: Date()) else { return 0 }
            return applications.filter { calendar.isDate($0.submittedDate, inSameDayAs: day) }.count
        }

        alerts = deriveAlerts()
    }

    private func deriveAlerts() -> [ReportAlert] {
        var found: [ReportAlert] = []

        let idle = students.filter { student in
            !applications.contains { $0.studentID == student.id && !$0.isClosed }
        }
        if !idle.isEmpty {
            found.append(ReportAlert(kind: .noApplications,
                                     title: "\(idle.count) students have not applied",
                                     detail: "They are ready or nearly ready and have no live application.",
                                     action: "Nudge to apply",
                                     studentCount: idle.count))
        }

        let thin = students.filter { !$0.missingSections.isEmpty }
        if !thin.isEmpty {
            found.append(ReportAlert(kind: .incompleteProfile,
                                     title: "\(thin.count) profiles have gaps",
                                     detail: "Missing skills, projects or an attached CV.",
                                     action: "Assign coaching",
                                     studentCount: thin.count))
        }

        let closing = internships.filter { $0.isClosingSoon && $0.applicants < 3 }
        if let soonest = closing.min(by: { $0.closingDate < $1.closingDate }) {
            found.append(ReportAlert(kind: .deadlineSoon,
                                     title: "\(soonest.title) closes \(soonest.deadlineLabel)",
                                     detail: "Only \(soonest.applicants) applicants so far.",
                                     action: "Promote to cohort",
                                     studentCount: students.count))
        }

        let stale = applications.filter {
            $0.stage == .underReview && Date().timeIntervalSince($0.lastUpdateDate) > 7 * 86_400
        }
        if !stale.isEmpty {
            found.append(ReportAlert(kind: .awaitingEmployer,
                                     title: "\(stale.count) applications awaiting a decision",
                                     detail: "No movement from the hiring company for over a week.",
                                     action: "Chase employers",
                                     studentCount: Set(stale.map(\.studentID)).count))
        }

        let noCV = students.filter { $0.cvFileName == nil }
        if !noCV.isEmpty {
            found.append(ReportAlert(kind: .missingDocumentation,
                                     title: "\(noCV.count) students without a CV",
                                     detail: "Employers cannot shortlist them until one is attached.",
                                     action: "Request uploads",
                                     studentCount: noCV.count))
        }

        return found
    }

    // MARK: Student actions

    func apply(to internship: Internship) {
        guard !hasApplied(to: internship.id) else {
            notify(Toast.warning("Already applied", "You have an open application for this role."))
            return
        }
        guard let studentID = currentStudentID else {
            notify(Toast.danger("Not your workspace", "Only a signed-in student can apply."))
            return
        }
        let now = Date()
        let application = Application(
            internshipID: internship.id, studentID: studentID, stage: .submitted,
            submittedDate: now, lastUpdateDate: now,
            nextAction: "Watch for a review",
            timeline: [TimelineEvent(title: "Application submitted",
                                     detail: internship.easyApply ? "Easy Apply profile sent" : "CV and portfolio attached",
                                     date: now)])
        applications.insert(application, at: 0)
        notify(Toast.success("Application sent", "\(internship.title) · \(internship.companyName)"))
        perform {
            try await self.service.save(application: application)
            await self.sync()
        }
    }

    func withdraw(_ application: Application) {
        var updated = application
        updated.stage = .declined
        updated.lastUpdateDate = Date()
        updated.nextAction = nil
        updated.timeline.append(TimelineEvent(title: "Withdrawn by you", date: Date()))
        replace(updated)
        candidates.removeAll { $0.student.id == application.studentID && $0.internshipID == application.internshipID }
        notify(Toast.info("Application withdrawn", "It no longer counts towards your open applications."))
        perform {
            try await self.service.withdraw(applicationID: application.id)
            await self.sync()
        }
    }

    func move(_ application: Application, to stage: ApplicationStage) {
        var updated = application
        updated.stage = stage
        updated.lastUpdateDate = Date()
        updated.timeline.append(TimelineEvent(title: stage.label, date: Date()))
        replace(updated)
        perform {
            try await self.service.record(stage: stage, on: application.id, title: stage.label,
                                          detail: nil)
            await self.sync()
        }
    }

    func toggleSave(_ internship: Internship) {
        guard let studentID = currentStudentID else { return }
        let isSaved = savedInternshipIDs.contains(internship.id)
        if isSaved {
            savedInternshipIDs.remove(internship.id)
            notify(Toast.info("Removed from saved", internship.title))
        } else {
            savedInternshipIDs.insert(internship.id)
            notify(Toast.success("Saved", "You will be alerted when this role changes."))
        }
        perform {
            try await self.service.setSaved(internship.id, saved: !isSaved, studentID: studentID)
        }
    }

    func saveSearch(_ search: SavedSearch) {
        guard let studentID = currentStudentID else { return }
        savedSearches.removeAll { $0.label == search.label }
        savedSearches.insert(search, at: 0)
        notify(Toast.success("Search saved", "We will flag new matches daily."))
        perform { try await self.service.save(search: search, studentID: studentID) }
    }

    func deleteSearch(_ search: SavedSearch) {
        savedSearches.removeAll { $0.id == search.id }
        notify(Toast.info("Search removed", search.label))
        perform { try await self.service.remove(searchID: search.id) }
    }

    func updateStudent(_ student: Student) {
        guard let index = students.firstIndex(where: { $0.id == student.id }) else { return }
        students[index] = student
        deriveRollups()
        perform { try await self.service.save(student: student) }
    }

    func addSkill(_ name: String, category: SkillCategory, evidence: String) {
        guard var student = currentStudent else { return }
        guard !student.skillNames.contains(where: { $0.caseInsensitiveCompare(name) == .orderedSame }) else {
            notify(Toast.warning("Skill already listed", name))
            return
        }
        let skill = StudentSkill(name: name, category: category,
                                 proficiency: .intermediate, evidence: evidence)
        student.skills.append(skill)
        student.profileStrength = min(100, student.profileStrength + 4)
        updateStudent(student)
        notify(Toast.success("Skill added", "\(name) now counts towards your matches."))
        perform {
            try await self.service.add(skill: skill, to: student.id)
            await self.sync()
        }
    }

    func removeSkill(_ skill: StudentSkill) {
        guard var student = currentStudent else { return }
        student.skills.removeAll { $0.id == skill.id }
        student.profileStrength = max(0, student.profileStrength - 4)
        updateStudent(student)
        perform {
            try await self.service.remove(skillID: skill.id)
            await self.sync()
        }
    }

    func setAvailability(_ availability: Availability) {
        guard var student = currentStudent else { return }
        student.availability = availability
        student.profileStrength = min(100, student.profileStrength + (availability == .undecided ? 0 : 3))
        updateStudent(student)
        notify(Toast.success("Availability updated", availability.rawValue))
    }

    func setInterests(_ interests: [String]) {
        guard var student = currentStudent else { return }
        student.interests = interests
        student.profileStrength = min(100, student.profileStrength + 3)
        updateStudent(student)
        perform {
            try await self.service.replace(interests: interests, for: student.id)
            await self.sync()
        }
    }

    func uploadCV(_ data: Data, named fileName: String) {
        guard var student = currentStudent else { return }
        student.cvFileName = fileName
        student.profileStrength = min(100, student.profileStrength + 6)
        updateStudent(student)
        notify(Toast.success("CV attached", fileName))
        perform {
            _ = try await self.service.upload(cv: data, fileName: fileName)
            await self.sync()
        }
    }

    func addProject(_ project: Project) {
        guard var student = currentStudent else { return }
        student.projects.insert(project, at: 0)
        student.profileStrength = min(100, student.profileStrength + 7)
        updateStudent(student)
        notify(Toast.success("Project added", project.title))
        perform {
            try await self.service.add(project: project, to: student.id)
            await self.sync()
        }
    }

    // MARK: Employer actions

    func post(_ internship: Internship) {
        guard let company = currentCompany else {
            notify(Toast.danger("Company not found", "Roles are published by your company account."))
            return
        }
        let owned = internship.stamped(from: company)
        internships.insert(owned, at: 0)
        notify(Toast.success("Role published",
                             "\(owned.title) is live to \(metrics.totalStudents) students."))
        perform {
            try await self.service.save(internship: owned, by: owned.companyID)
            await self.sync()
        }
    }

    func update(_ internship: Internship) {
        guard let index = internships.firstIndex(where: { $0.id == internship.id }) else { return }
        internships[index] = internship
        perform {
            try await self.service.save(internship: internship,
                                        by: self.employerCompanyID ?? internship.companyID)
        }
    }

    func close(internship: Internship) {
        var updated = internship
        updated.status = .closed
        updated.closingDate = Date()
        update(updated)
        notify(Toast.info("Applications closed", updated.title))
    }

    func move(candidate: Candidate, to stage: ApplicationStage) {
        guard let index = candidates.firstIndex(where: { $0.id == candidate.id }) else { return }
        var updated = candidate
        updated.status = stage
        candidates[index] = updated
        if let application = applications.first(where: {
            $0.studentID == candidate.student.id && $0.internshipID == candidate.internshipID
        }) {
            move(application, to: stage)
        }
        notify(Toast.success("\(candidate.student.firstName) → \(stage.label)",
                             "The student is notified in the app and by email."))
        perform {
            try await self.service.record(stage: stage, on: candidate.id, title: stage.label,
                                          detail: nil)
            await self.sync()
        }
    }

    func saveCompany(_ company: Company) {
        guard let index = companies.firstIndex(where: { $0.id == company.id }) else {
            companies.append(company)
            return
        }
        companies[index] = company
        notify(Toast.success("Company updated", company.name))
        perform { try await self.service.save(company: company) }
    }

    // MARK: Manager actions

    /// Verified companies are the only ones whose roles reach students.
    func setVerified(_ company: Company, verified: Bool) {
        guard let index = companies.firstIndex(where: { $0.id == company.id }) else { return }
        companies[index].isVerified = verified
        notify(Toast.success(verified ? "Company verified" : "Verification withdrawn",
                             company.name))
        perform {
            try await self.service.verify(companyID: company.id, verified: verified)
            await self.sync()
        }
    }

    func move(_ placement: Placement, to stage: PlacementStage) {
        guard let index = placements.firstIndex(where: { $0.id == placement.id }) else { return }
        placements[index].stage = stage
        placements[index].readiness = max(placements[index].readiness, stage.observedReadiness)
        notify(Toast.success("\(placement.studentName) moved", "Now in \(stage.label)."))
        perform {
            try await self.service.save(placement: self.placements[index])
            await self.sync()
        }
    }

    func nudge(_ alert: ReportAlert) {
        alerts.removeAll { $0.id == alert.id }
        notify(Toast.success("Sent to \(alert.studentCount) students", alert.title))
    }

    // MARK: Photos

    /// Keeps the header and the account row in step with a name edited on the profile.
    func updateAccountName(_ name: String) async {
        await auth.updateDisplayName(name)
    }

    func setAvatarPhoto(_ data: Data, extent: String) {
        perform {
            let path = try await self.service.uploadAvatar(data, extent: extent)
            await self.auth.setAvatarPath(path)
            await self.sync()
            self.notify(Toast.success("Photo updated", "Visible to your advisers and employers you apply to."))
        }
    }

    func setCompanyLogo(_ data: Data, extent: String) {
        guard let company = currentCompany, let companyID = employerCompanyID else { return }
        perform {
            let path = try await self.service.uploadLogo(data, companyID: companyID, extent: extent)
            var updated = company
            updated.logoPath = path
            self.saveCompany(updated)
            await self.sync()
            self.notify(Toast.success("Logo updated", updated.name))
        }
    }

    // MARK: Messaging

    func send(_ body: String, in threadID: UUID) {
        guard let index = threads.firstIndex(where: { $0.id == threadID }) else { return }
        let trimmed = body.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let message = Message(threadID: threadID, body: String(trimmed.prefix(4000)),
                              sentAt: Date(), fromCurrentUser: true)
        threads[index].messages.append(message)
        threads[index].unread = 0
        perform { try await self.service.send(message: message) }
    }

    func markRead(_ threadID: UUID) {
        guard let index = threads.firstIndex(where: { $0.id == threadID }), threads[index].unread > 0 else { return }
        threads[index].unread = 0
        perform { try await self.service.markRead(threadID: threadID) }
    }

    func openThread(with candidate: Candidate, as senderName: String) {
        startThread(with: candidate.student.id,
                    subject: "\(senderName) recruitment",
                    context: candidate.student.programme,
                    greeting: "Thanks for your interest — a few questions about your availability.")
    }

    func openThread(with student: Student, from senderName: String) {
        startThread(with: student.id,
                    subject: "\(senderName) · MCRI Connect",
                    context: "\(student.programme) · \(student.year)",
                    greeting: "Hi \(student.firstName) — \(senderName) here. Your profile is ready to "
                        + "show to employers; let's close the last gaps this week.")
    }

    private func startThread(with peerID: UUID, subject: String, context: String, greeting: String) {
        if let existing = threads.first(where: { $0.participantID == peerID }) {
            markRead(existing.id)
            routerTarget = existing.id
            return
        }
        perform {
            let id = try await self.service.openThread(peerID: peerID, subject: subject,
                                                       context: context, greeting: greeting)
            self.routerTarget = id
            await self.sync()
        }
    }

    /// Set when a thread has just been created so the caller can push straight into it.
    @Published var routerTarget: UUID?

    func clearRouterTarget() { routerTarget = nil }

    func dismissToast() {
        toast = nil
    }

    // MARK: Private

    private func notify(_ message: Toast) {
        toast = message
    }

    private func replace(_ application: Application) {
        guard let index = applications.firstIndex(where: { $0.id == application.id }) else { return }
        applications[index] = application
    }

    /// Fire the write, surface the failure, and never block the interface on the network.
    private func perform(_ work: @escaping () async throws -> Void) {
        Task {
            do {
                try await work()
            } catch {
                notify(Toast.danger("Could not save", error.localizedDescription))
            }
        }
    }

    #if DEBUG
    /// Previews and `simctl` screenshots have no Supabase account to read from, so they swap
    /// the shared store over to the bundled snapshot and seed a matching session. Compiled out
    /// of Release: a shipping build can only reach a workspace through the server's role.
    func previewAsSignedIn(role: UserRole) {
        service = LocalDataService()
        switch role {
        case .student:
            auth.seedForPreview(role: .student, id: SampleData.alex.id,
                                displayName: SampleData.alex.fullName)
        case .employer:
            auth.seedForPreview(role: .employer, id: SampleData.employerAccountID,
                                displayName: "Priya Naidoo", companyID: SampleData.orbitLabs.id)
        case .programManager:
            auth.seedForPreview(role: .programManager, id: SampleData.managerAccountID,
                                displayName: "Nomsa Dube")
        }
        Task { await load() }
    }
    #endif
}

private extension PlacementStage {
    /// Moving a student forward implies their readiness reached the stage floor.
    var observedReadiness: Int {
        switch self {
        case .preparing: return 0
        case .applying: return 55
        case .shortlisted: return 70
        case .interviewing: return 80
        case .placed: return 90
        }
    }
}

extension Internship {
    /// A role always carries the signed-in employer's own company details, whatever the form
    /// held — the company behind a posting is never free text typed by whoever publishes it.
    func stamped(from company: Company) -> Internship {
        var copy = self
        copy.companyID = company.id
        copy.companyName = company.name
        copy.companyInitials = company.initials
        copy.companyLogoPath = company.logoPath
        copy.companyIsVerified = company.isVerified
        return copy
    }
}
