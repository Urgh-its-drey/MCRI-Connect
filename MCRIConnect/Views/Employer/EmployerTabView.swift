import SwiftUI

/// The employer workspace: Dashboard, Internships, Candidates, Messages, Company.
struct EmployerTabView: View {
    @EnvironmentObject private var store: AppStore
    @StateObject private var router = Router()

    private var items: [MCRITabBar.Item] {
        [
            MCRITabBar.Item(title: "Dashboard", symbol: "square.grid.2x2.fill"),
            MCRITabBar.Item(title: "Internships", symbol: "briefcase.fill"),
            MCRITabBar.Item(title: "Candidates", symbol: "person.2.fill",
                            badge: store.employerCandidates.filter { $0.status == .submitted }.count),
            MCRITabBar.Item(title: "Messages", symbol: "bubble.left.fill",
                            badge: store.unreadMessages),
            MCRITabBar.Item(title: "Company", symbol: "building.2.fill"),
        ]
    }

    var body: some View {
        NavigationStack(path: $router.path) {
            MCRIRootTabView(selection: $router.tab, items: items) { index in
                switch index {
                case 0: EmployerDashboardView()
                case 1: EmployerInternshipsView()
                case 2: CandidatePipelineView()
                case 3: MessagesView()
                default: CompanyView()
                }
            }
            .mcriDestinations()
        }
        .environmentObject(router)
    }
}

private struct EmployerTabViewPreview1: PreviewProvider {
    static var previews: some View {
    MCRIPreviewScreen(signedInAs: .employer, inNavigationStack: false) { EmployerTabView() }
}
}
