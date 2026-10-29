import Foundation
import Combine

/// The employer's view of the same data the student sees: their own roles, the
/// candidates against those roles, and the stage each candidate sits at.
@MainActor
final class EmployerViewModel: ObservableObject {
    struct StageColumn: Identifiable {
        var stage: ApplicationStage
        var items: [Candidate]
        var id: String { stage.rawValue }
    }

    struct RoleLoad: Identifiable {
        var role: Internship
        var applicants: Int
        var awaitingReview: Int
        var id: UUID { role.id }
    }

    private let store: AppStore

    convenience init() {
        self.init(store: AppStore.shared)
    }

    init(store: AppStore) {
        self.store = store
    }

    @Published var query = ""
    @Published var stageFilter: ApplicationStage?
    @Published var roleFilter: UUID?

    // MARK: Reads

    var company: Company { SampleData.orbitLabs }

    var postings: [Internship] { store.openRoles }

    var livePostings: [Internship] { postings.filter { $0.daysUntilDeadline > 0 } }

    var closedPostings: [Internship] { postings.filter { $0.daysUntilDeadline <= 0 } }

    var pipeline: [Candidate] { store.employerCandidates }

    var visibleCandidates: [Candidate] {
        let needle = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return pipeline.filter { candidate in
            if let stageFilter, candidate.status != stageFilter { return false }
            if let roleFilter, candidate.internshipID != roleFilter { return false }
            guard !needle.isEmpty else { return true }
            return candidate.name.lowercased().contains(needle)
                || candidate.student.programme.lowercased().contains(needle)
                || candidate.topSkills.contains { $0.lowercased().contains(needle) }
        }
    }

    var stageBoard: [StageColumn] {
        ApplicationStage.pipelineStages.compactMap { stage in
            let items = visibleCandidates.filter { $0.status == stage }
            return items.isEmpty ? nil : StageColumn(stage: stage, items: items)
        }
    }

    func candidates(in stage: ApplicationStage) -> [Candidate] {
        pipeline.filter { $0.status == stage }
    }

    var awaitingReview: Int { candidates(in: .submitted).count }

    var inInterview: Int { candidates(in: .interviewScheduled).count }

    var offersOut: Int { candidates(in: .offered).count }

    var topPicks: [Candidate] { pipeline.filter(\.isTopPick) }

    var averageMatch: Int {
        guard !pipeline.isEmpty else { return 0 }
        return Int(pipeline.map(\.match).reduce(0, +) / pipeline.count)
    }

    /// The candidate the employer is most at risk of losing: highest fit, least progress.
    var firstToAction: Candidate? {
        pipeline.first { $0.status == .submitted }
    }

    var closingSoon: [Internship] { livePostings.filter { $0.isClosingSoon } }

    var roleLoads: [RoleLoad] {
        postings.map { role in
            let applicants = store.candidates(for: role.id)
            return RoleLoad(role: role, applicants: applicants.count,
                            awaitingReview: applicants.filter { $0.status == .submitted }.count)
        }
        .sorted { $0.applicants > $1.applicants }
    }

    func role(for candidate: Candidate) -> Internship? {
        store.internship(for: candidate.internshipID)
    }

    func isSaved(_ roleID: UUID) -> Bool { store.savedInternshipIDs.contains(roleID) }

    // MARK: Actions

    func advance(_ candidate: Candidate) {
        guard let next = nextStage(for: candidate) else { return }
        store.move(candidate: candidate, to: next)
    }

    func move(_ candidate: Candidate, to stage: ApplicationStage) {
        store.move(candidate: candidate, to: stage)
    }

    /// Message from the pipeline: reuses an existing thread when there is one.
    func message(_ candidate: Candidate) -> UUID {
        store.openThread(with: candidate, as: company.name).id
    }

    func select(role: Internship) {
        roleFilter = role.id
        stageFilter = nil
    }

    func clearFilters() {
        roleFilter = nil
        stageFilter = nil
        query = ""
    }

    var hasFilters: Bool { roleFilter != nil || stageFilter != nil || !query.isEmpty }

    private func nextStage(for candidate: Candidate) -> ApplicationStage? {
        switch candidate.status {
        case .submitted: return .underReview
        case .underReview: return .shortlisted
        case .shortlisted: return .interviewScheduled
        case .interviewScheduled: return .offered
        case .offered, .declined: return nil
        }
    }
}
