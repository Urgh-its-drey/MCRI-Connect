import Foundation
import Combine

/// Owns one role screen: the explanation of the match, the apply state, and the
/// similar roles that keep the screen useful even after applying.
@MainActor
final class InternshipDetailViewModel: ObservableObject {
    private let store: AppStore
    let internship: Internship

    @Published var showGapSheet = false

    convenience init(_ internship: Internship) {
        self.init(internship, store: AppStore.shared)
    }

    init(_ internship: Internship, store: AppStore) {
        self.store = store
        self.internship = internship
    }

    var result: MatchResult? { store.match(for: internship) }

    var score: Int { result?.score ?? 0 }

    var isSaved: Bool { store.savedInternshipIDs.contains(internship.id) }

    var hasApplied: Bool { store.hasApplied(to: internship.id) }

    var application: Application? {
        store.studentApplications.first { $0.internshipID == internship.id && !$0.isClosed }
    }

    var matchedSkills: [String] { result?.matchedSkills ?? [] }

    var missingSkills: [String] { result?.missingSkills ?? [] }

    var gaps: [MatchGap] { result?.gaps ?? [] }

    var signals: [MatchSignal] { result?.signals ?? [] }

    var weakest: MatchComponent? { result?.breakdown.weakest }

    var applicantsAhead: Int { internship.applicants }

    var profileStrength: Int { store.currentStudent?.profileStrength ?? 0 }

    var similarRoles: [MatchedRole] {
        guard let student = store.currentStudent else { return [] }
        return store.publishedRoles
            .filter { $0.id != internship.id && $0.category == internship.category }
            .map { MatchedRole(internship: $0, result: MatchEngine.shared.result(for: student, on: $0)) }
            .sorted { $0.score > $1.score }
            .prefix(3)
            .map { $0 }
    }

    var timelineItem: TimelineEvent {
        TimelineEvent(title: "Viewed \(internship.title)",
                      detail: "Score \(score)% · \(internship.companyName)",
                      date: Date())
    }

    func toggleSave() { store.toggleSave(internship) }

    func apply() { store.apply(to: internship) }
}
