import Foundation
import Combine

/// Home is a summary of three questions: how ready am I, what should I open next,
/// and what needs a response today.
@MainActor
final class HomeViewModel: ObservableObject {
    private let store: AppStore

    convenience init() {
        self.init(store: AppStore.shared)
    }

    init(store: AppStore) {
        self.store = store
    }

    var student: Student? { store.currentStudent }

    var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        default: return "Good evening"
        }
    }

    var firstName: String { store.currentStudent?.firstName ?? "there" }

    var recommended: [MatchedRole] { store.recommendedRoles }

    var activeApplications: [Application] {
        store.studentApplications.filter { !$0.isClosed }
    }

    var needsResponse: [Application] {
        activeApplications.filter { $0.nextAction != nil }
    }

    var closingSoon: [MatchedRole] {
        store.recommendedRoles
            .filter { $0.internship.isClosingSoon || $0.internship.daysUntilDeadline <= 7 }
            .prefix(2)
            .map { $0 }
    }

    var unreadMessages: Int { store.unreadMessages }

    var profileStrength: Int { store.currentStudent?.profileStrength ?? 0 }

    var missingSections: [String] { store.currentStudent?.missingSections ?? [] }

    var savedCount: Int { store.savedInternshipIDs.count }
}
