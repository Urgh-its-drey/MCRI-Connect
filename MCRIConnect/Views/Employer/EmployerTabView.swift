import SwiftUI

/// The employer workspace: Dashboard, Roles, Candidates, Messages, Company.
struct EmployerTabView: View {
    @EnvironmentObject private var store: AppStore
    @StateObject private var router = Router()

    private var items: [MCRITabBar.Item] {
        MCRIPreview.tabs(for: .employer, badges: [
            2: store.employerCandidates.filter { $0.status == .submitted }.count,
            3: store.unreadMessages,
        ])
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
            .mcriFollowThreadTargets(router, role: .employer)
        }
        .environmentObject(router)
    }
}

private struct EmployerTabViewPreview1: PreviewProvider {
    static var previews: some View {
        MCRIPreviewScreen(signedInAs: .employer, inNavigationStack: false) { EmployerTabView() }
    }
}
