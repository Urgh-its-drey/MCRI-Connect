import SwiftUI
import Combine

/// Every push in the app is one of these, so any screen can navigate without
/// knowing which tab it lives in.
enum Route: Hashable {
    case internship(UUID)
    case application(UUID)
    case candidate(UUID)
    case student(UUID)
    case thread(UUID)
    case company(UUID)
    case createInternship
    case editInternship(UUID)
    case internships
    case students
    case companies
    case placementPipeline
    case reports
    case settings
    case savedSearches
    case skillPicker
    case account
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

    /// Screenshots are taken against the bundled snapshot: the Supabase tables only exist
    /// once schema.sql has been pasted into the dashboard, which is a manual step.
    static var usesSampleData: Bool {
        argument(named: "-mcri.sample").map { $0 != "0" } ?? false
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

    /// Opens a thread from anywhere in the workspace: the Messages tab owns the list, so a
    /// thread started on a candidate or student screen lands there with the stack behind it.
    func openThread(_ id: UUID, in role: UserRole) {
        if let index = role.tabTitles.firstIndex(of: "Messages") { select(tab: index) }
        go(.thread(id))
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

    /// Picks up a thread id the store published after `openThread`, then clears it.
    func mcriFollowThreadTargets(_ router: Router, role: UserRole) -> some View {
        modifier(MCRIThreadTargetFollower(router: router, role: role))
    }
}

private struct MCRIThreadTargetFollower: ViewModifier {
    @EnvironmentObject private var store: AppStore
    let router: Router
    let role: UserRole

    func body(content: Content) -> some View {
        content.onChange(of: store.routerTarget) { _, id in
            guard let id else { return }
            store.clearRouterTarget()
            router.openThread(id, in: role)
        }
    }
}

/// Resolves a route against the live store so destinations always render fresh data.
struct DestinationView: View {
    @EnvironmentObject private var store: AppStore
    @EnvironmentObject private var auth: AuthService
    var route: Route

    var body: some View {
        // The route map is shared by all three workspaces, so every destination re-checks the
        // server's role before rendering another workspace's screen.
        guard auth.canOpen(ownerRole) else {
            return AnyView(MCRIEmptyState(symbol: "lock.circle",
                                          title: "Not your workspace",
                                          message: "Sign in with the account that owns this screen."))
        }
        return AnyView(destination)
    }

    /// Which account type is allowed to see this route.
    private var ownerRole: UserRole {
        switch route {
        case .internship, .application, .student, .savedSearches, .skillPicker, .company, .account:
            return auth.session.role
        case .candidate, .createInternship, .editInternship, .internships:
            return .employer
        case .students, .companies, .placementPipeline, .reports, .settings:
            return .programManager
        case .thread:
            return auth.session.role
        }
    }

    @ViewBuilder private var destination: some View {
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
        case .student(let id):
            if let student = store.student(for: id) {
                StudentDetailView(student: student)
            }
        case .thread(let id):
            if store.threads.contains(where: { $0.id == id }) {
                MessageThreadView(threadID: id)
            }
        case .company(let id):
            if let company = store.company(for: id) {
                CompanyProfileView(company: company)
            }
        case .createInternship:
            CreateInternshipView()
        case .editInternship(let id):
            if let role = store.internship(for: id) {
                CreateInternshipView(role: role)
            }
        case .internships:
            EmployerInternshipsView()
        case .students:
            ManagerStudentsView()
        case .companies:
            ManagerEmployersView()
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
        case .account:
            AccountView()
        }
    }
}
