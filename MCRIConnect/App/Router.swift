import SwiftUI
import Combine

/// Every push in the app is one of these, so any screen can navigate without
/// knowing which tab it lives in.
enum Route: Hashable {
    case internship(UUID)
    case application(UUID)
    case candidate(UUID)
    case thread(UUID)
    case createInternship
    case internships
    case students
    case placementPipeline
    case reports
    case settings
    case savedSearches
    case skillPicker
}

/// Opening a specific workspace or tab straight from `simctl launch` is the only
/// way to screenshot every screen without a UI-test target. Release builds ignore it.
#if DEBUG
enum DebugLaunch {
    static var role: UserRole? {
        argument(named: "-mcri.role").flatMap(UserRole.init(rawValue:))
    }

    static var tab: Int? {
        argument(named: "-mcri.tab").flatMap(Int.init)
    }

    static func argument(named key: String) -> String? {
        let arguments = ProcessInfo.processInfo.arguments
        guard let index = arguments.firstIndex(of: key), arguments.count > index + 1 else { return nil }
        return arguments[index + 1]
    }
}
#endif

/// One navigation stack per role workspace. Switching tabs returns that tab to its
/// root, which is what the native tab bar does.
@MainActor
final class Router: ObservableObject {
    @Published var path = NavigationPath()
    @Published var tab = 0

    init() {
        #if DEBUG
        if let start = DebugLaunch.tab { tab = min(max(start, 0), 4) }
        #endif
    }

    func go(_ route: Route) {
        path.append(route)
    }

    func select(tab index: Int) {
        tab = index
        path = NavigationPath()
    }

    func popToRoot() {
        path = NavigationPath()
    }

    func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }
}

extension View {
    /// Attaches the destination map once per stack instead of per screen.
    func mcriDestinations() -> some View {
        navigationDestination(for: Route.self) { route in
            DestinationView(route: route)
        }
    }
}

/// Resolves a route against the live store so destinations always render fresh data.
struct DestinationView: View {    @EnvironmentObject private var store: AppStore
    var route: Route

    var body: some View {
        switch route {
        case .internship(let id):
            if let role = store.internship(for: id) {
                InternshipDetailView(role: role)
            }
        case .application(let id):
            if let application = store.application(for: id) {
                ApplicationDetailView(application: application)
            }
        case .candidate(let id):
            if let candidate = store.candidates.first(where: { $0.id == id }) {
                CandidateProfileView(candidate: candidate)
            }
        case .thread(let id):
            if let thread = store.threads.first(where: { $0.id == id }) {
                MessageThreadView(threadID: thread.id)
            }
        case .createInternship:
            CreateInternshipView()
        case .internships:
            EmployerInternshipsView()
        case .students:
            ManagerStudentsView()
        case .placementPipeline:
            PlacementPipelineView()
        case .reports:
            ReportsView()
        case .settings:
            ManagerSettingsView()
        case .savedSearches:
            SavedSearchesView()
        case .skillPicker:
            SkillPickerView()
        }
    }
}
