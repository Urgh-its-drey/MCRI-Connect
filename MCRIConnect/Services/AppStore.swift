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
}

/// Single source of truth for the signed-in student, the employer's pipeline and
/// the programme roll-up. Views read derived properties instead of re-filtering.
@MainActor
final class AppStore: ObservableObject {
    static let shared = AppStore(service: LocalDataService())

    private let service: DataService

    @Published private(set) var isLoading = false
    @Published private(set) var loadError: String?

    @Published var students: [Student] = []
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

    let currentStudentID = SampleData.alex.id
    let employerCompanyID = SampleData.orbitLabs.id

    init(service: DataService = LocalDataService()) {
        self.service = service
    }

    // MARK: Derived reads

    var currentStudent: Student? {
        students.first { $0.id == currentStudentID }
    }

    var studentApplications: [Application] {
        applications.filter { $0.studentID == currentStudentID }
    }

    var openRoles: [Internship] {
        internships.filter { $0.companyID == employerCompanyID }
    }

    var unreadMessages: Int {
        threads.reduce(0) { $0 + $1.unread }
    }

    var activeApplications: Int {
        studentApplications.filter { !$0.isClosed }.count
    }

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
        let scored = internships
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
            async let loadedStudents = service.students()
            async let loadedInternships = service.internships()
            async let loadedThreads = service.threads()
            async let loadedPlacements = service.placements()
            async let loadedMetrics = service.metrics()
            async let loadedReadiness = service.readiness()
            async let loadedWeekly = service.weeklyApplications()
            async let loadedAlerts = service.alerts()
            async let loadedSearches = service.savedSearches()

            let studentsResult = try await loadedStudents
            let internshipsResult = try await loadedInternships

            students = studentsResult
            internships = internshipsResult
            threads = try await loadedThreads
            placements = try await loadedPlacements
            metrics = try await loadedMetrics
            readiness = try await loadedReadiness
            weeklyApplications = try await loadedWeekly
            alerts = try await loadedAlerts
            savedSearches = try await loadedSearches
            applications = try await service.applications(for: currentStudentID)
            savedInternshipIDs = Set([SampleData.dataAnalystIntern.id])
            candidates = internshipsResult.flatMap { SampleData.candidates(for: $0) }
            isLoading = false
        } catch {
            loadError = error.localizedDescription
            isLoading = false
        }
    }

    // MARK: Student actions

    func apply(to internship: Internship) {
        guard !hasApplied(to: internship.id) else {
            notify(Toast.warning("Already applied", "You have an open application for this role."))
            return
        }
        let now = Date()
        let application = Application(
            internshipID: internship.id, studentID: currentStudentID, stage: .submitted,
            submittedDate: now, lastUpdateDate: now,
            nextAction: "Watch for a review",
            timeline: [TimelineEvent(title: "Application submitted",
                                     detail: internship.easyApply ? "Easy Apply profile sent" : "CV and portfolio attached",
                                     date: now)])
        applications.insert(application, at: 0)
        if internship.companyID == employerCompanyID, let student = currentStudent {
            candidates.insert(SampleData.candidate(student, internship: internship, status: .submitted), at: 0)
        }
        Task { try? await service.save(application: application) }
        notify(Toast.success("Application sent",
                             "\(internship.title) · \(internship.companyName)"))
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
    }

    func move(_ application: Application, to stage: ApplicationStage) {
        var updated = application
        updated.stage = stage
        updated.lastUpdateDate = Date()
        updated.timeline.append(TimelineEvent(title: stage.label, date: Date()))
        replace(updated)
    }

    func toggleSave(_ internship: Internship) {
        if savedInternshipIDs.contains(internship.id) {
            savedInternshipIDs.remove(internship.id)
            notify(Toast.info("Removed from saved", internship.title))
        } else {
            savedInternshipIDs.insert(internship.id)
            notify(Toast.success("Saved", "You will be alerted when this role changes."))
        }
    }

    func saveSearch(_ search: SavedSearch) {
        savedSearches.removeAll { $0.label == search.label }
        savedSearches.insert(search, at: 0)
        Task { try? await service.save(search: search) }
        notify(Toast.success("Search saved", "We will flag new matches daily."))
    }

    func deleteSearch(_ search: SavedSearch) {
        savedSearches.removeAll { $0.id == search.id }
        notify(Toast.info("Search removed", search.label))
    }

    func updateStudent(_ student: Student) {
        guard let index = students.firstIndex(where: { $0.id == student.id }) else { return }
        students[index] = student
        Task { try? await service.save(student: student) }
    }

    func addSkill(_ name: String, category: SkillCategory, evidence: String) {
        guard var student = currentStudent else { return }
        guard !student.skillNames.contains(where: { $0.caseInsensitiveCompare(name) == .orderedSame }) else {
            notify(Toast.warning("Skill already listed", name))
            return
        }
        student.skills.append(StudentSkill(name: name, category: category,
                                           proficiency: .intermediate, evidence: evidence))
        student.profileStrength = min(100, student.profileStrength + 4)
        updateStudent(student)
        notify(Toast.success("Skill added", "\(name) now counts towards your matches."))
    }

    func removeSkill(_ skill: StudentSkill) {
        guard var student = currentStudent else { return }
        student.skills.removeAll { $0.id == skill.id }
        student.profileStrength = max(0, student.profileStrength - 4)
        updateStudent(student)
    }

    func setAvailability(_ availability: Availability) {
        guard var student = currentStudent else { return }
        student.availability = availability
        student.profileStrength = min(100, student.profileStrength + (availability == .undecided ? 0 : 3))
        updateStudent(student)
        notify(Toast.success("Availability updated", availability.rawValue))
    }

    func uploadCV(named fileName: String) {
        guard var student = currentStudent else { return }
        student.cvFileName = fileName
        student.profileStrength = min(100, student.profileStrength + 6)
        updateStudent(student)
        notify(Toast.success("CV attached", fileName))
    }

    func addProject(_ project: Project) {
        guard var student = currentStudent else { return }
        student.projects.insert(project, at: 0)
        student.profileStrength = min(100, student.profileStrength + 7)
        updateStudent(student)
        notify(Toast.success("Project added", project.title))
    }

    // MARK: Employer actions

    func post(_ internship: Internship) {
        internships.insert(internship, at: 0)
        Task { try? await service.save(internship: internship) }
        notify(Toast.success("Role published", "\(internship.title) is live to \(metrics.totalStudents) students."))
    }

    func update(_ internship: Internship) {
        guard let index = internships.firstIndex(where: { $0.id == internship.id }) else { return }
        internships[index] = internship
        Task { try? await service.save(internship: internship) }
    }

    func close(internship: Internship) {
        var updated = internship
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
    }

    // MARK: Messaging

    func send(_ body: String, in threadID: UUID) {
        guard let index = threads.firstIndex(where: { $0.id == threadID }) else { return }
        var thread = threads[index]
        thread.messages.append(Message(threadID: threadID, body: body, sentAt: Date(), fromCurrentUser: true))
        threads[index] = thread
        Task { try? await service.save(thread: thread) }
    }

    func markRead(_ threadID: UUID) {
        guard let index = threads.firstIndex(where: { $0.id == threadID }), threads[index].unread > 0 else { return }
        threads[index].unread = 0
    }

    func openThread(with candidate: Candidate, as senderName: String) -> MessageThread {
        if let existing = threads.first(where: { $0.participantName == candidate.name }) {
            markRead(existing.id)
            return existing
        }
        let threadID = UUID()
        let thread = MessageThread(
            id: threadID,
            participantName: candidate.name,
            participantInitials: candidate.initials,
            context: "\(senderName) · MCRI Connect",
            messages: [Message(threadID: threadID, body: "Thanks for your interest — a few questions about your "
                        + "availability.", sentAt: Date(), fromCurrentUser: true)])
        threads.insert(thread, at: 0)
        return thread
    }

    func openThread(with student: Student, from senderName: String) -> MessageThread {
        if let existing = threads.first(where: { $0.participantName == student.fullName }) {
            markRead(existing.id)
            return existing
        }
        let threadID = UUID()
        let thread = MessageThread(
            id: threadID,
            participantName: student.fullName,
            participantInitials: student.initials,
            context: "\(student.programme) · \(student.year)",
            messages: [Message(threadID: threadID,
                               body: "Hi \(student.firstName) — \(senderName) here. Your profile is ready to "
                                   + "show to employers; let's close the last gaps this week.",
                               sentAt: Date(), fromCurrentUser: true)])
        threads.insert(thread, at: 0)
        return thread
    }

    // MARK: Programme manager

    func move(_ placement: Placement, to stage: PlacementStage) {
        guard let index = placements.firstIndex(where: { $0.id == placement.id }) else { return }
        placements[index].stage = stage
        placements[index].readiness = max(placements[index].readiness, stage.observedReadiness)
        notify(Toast.success("\(placement.studentName) moved", "Now in \(stage.label)."))
    }

    func nudge(_ alert: ReportAlert) {
        alerts.removeAll { $0.id == alert.id }
        notify(Toast.success("Sent to \(alert.studentCount) students", alert.title))
    }

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
