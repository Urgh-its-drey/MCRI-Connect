import Foundation
import Combine

/// Totals first, then the list — the tracker answers "how many, and which one
/// needs me today" before it shows anything else.
@MainActor
final class ApplicationsViewModel: ObservableObject {
    enum Scope: String, CaseIterable, Identifiable {
        case active = "Active"
        case shortlisted = "Shortlisted"
        case closed = "Closed"
        case all = "All"

        var id: String { rawValue }
    }

    @Published var scope: Scope = .active

    private let store: AppStore

    convenience init() {
        self.init(store: AppStore.shared)
    }

    init(store: AppStore) {
        self.store = store
    }

    var all: [Application] { store.studentApplications }

    var visible: [Application] { applications(in: scope) }

    func applications(in scope: Scope) -> [Application] {
        switch scope {
        case .active: return all.filter { !$0.isClosed && $0.stage != .offered }
        case .shortlisted: return all.filter { $0.stage == .shortlisted || $0.stage == .interviewScheduled }
        case .closed: return all.filter { $0.isClosed || $0.stage == .offered }
        case .all: return all
        }
    }

    var awaitingResponse: Int {
        all.filter { !$0.isClosed && $0.nextAction != nil }.count
    }

    var counts: [(label: String, value: Int, symbol: String, tone: MCRIStatusTone)] {
        [
            ("Open", all.filter { !$0.isClosed }.count, "paperplane.fill", .information),
            ("Shortlisted", all.filter { $0.stage == .shortlisted || $0.stage == .interviewScheduled }.count,
             "star.fill", .attention),
            ("Offers", all.filter { $0.stage == .offered }.count, "hand.thumbsup.fill", .positive),
            ("Closed", all.filter { $0.isClosed }.count, "xmark.circle.fill", .blocked),
        ]
    }

    var oldestAwaiting: Application? {
        all.filter { !$0.isClosed && $0.stage == .underReview }
            .min { $0.submittedDate < $1.submittedDate }
    }

    func role(for application: Application) -> Internship? {
        store.internship(for: application.internshipID)
    }
}
