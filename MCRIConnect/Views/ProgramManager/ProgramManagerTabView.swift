import SwiftUI

/// The programme manager workspace: Overview, Students, Placements, Reports, Settings.
struct ProgramManagerTabView: View {
    @EnvironmentObject private var store: AppStore
    @StateObject private var router = Router()

    private var items: [MCRITabBar.Item] {
        [
            MCRITabBar.Item(title: "Overview", symbol: "chart.bar.fill"),
            MCRITabBar.Item(title: "Students", symbol: "person.2.fill"),
            MCRITabBar.Item(title: "Placements", symbol: "arrow.triangle.branch"),
            MCRITabBar.Item(title: "Reports", symbol: "doc.text.fill", badge: store.alerts.count),
            MCRITabBar.Item(title: "Settings", symbol: "gearshape.fill"),
        ]
    }

    var body: some View {
        NavigationStack(path: $router.path) {
            MCRIRootTabView(selection: $router.tab, items: items) { index in
                switch index {
                case 0: ManagerOverviewView()
                case 1: ManagerStudentsView()
                case 2: PlacementPipelineView()
                case 3: ReportsView()
                default: ManagerSettingsView()
                }
            }
            .mcriDestinations()
        }
        .environmentObject(router)
    }
}

private struct ProgramManagerTabViewPreview1: PreviewProvider {
    static var previews: some View {
    MCRIPreviewScreen(signedInAs: .programManager, inNavigationStack: false) { ProgramManagerTabView() }
}
}
