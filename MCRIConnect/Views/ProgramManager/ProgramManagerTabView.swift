import SwiftUI

/// The programme manager workspace: Overview, Students, Employers, Placements, Reports.
/// Settings is a pushed screen rather than a tab, which keeps all five tabs on the
/// programme's own data.
struct ProgramManagerTabView: View {
    @EnvironmentObject private var store: AppStore
    @StateObject private var router = Router()

    private var items: [MCRITabBar.Item] {
        MCRIPreview.tabs(for: .programManager, badges: [
            2: store.pendingCompanies.count,
            4: store.alerts.count,
        ])
    }

    var body: some View {
        NavigationStack(path: $router.path) {
            MCRIRootTabView(selection: $router.tab, items: items) { index in
                switch index {
                case 0: ManagerOverviewView()
                case 1: ManagerStudentsView()
                case 2: ManagerEmployersView()
                case 3: PlacementPipelineView()
                default: ReportsView()
                }
            }
            .mcriDestinations()
            .mcriFollowThreadTargets(router, role: .programManager)
        }
        .environmentObject(router)
    }
}

private struct ProgramManagerTabViewPreview1: PreviewProvider {
    static var previews: some View {
        MCRIPreviewScreen(signedInAs: .programManager, inNavigationStack: false) { ProgramManagerTabView() }
    }
}
