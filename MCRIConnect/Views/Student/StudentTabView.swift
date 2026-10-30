import SwiftUI

/// The student workspace. Titles and icons come from `UserRole` so the tab bar and the
/// role metadata cannot drift apart.
struct StudentTabView: View {
    @EnvironmentObject private var store: AppStore
    @StateObject private var router = Router()

    private var items: [MCRITabBar.Item] {
        MCRIPreview.tabs(for: .student, badges: [
            2: store.activeApplications,
            3: store.unreadMessages,
        ])
    }

    var body: some View {
        NavigationStack(path: $router.path) {
            MCRIRootTabView(selection: $router.tab, items: items) { index in
                switch index {
                case 0: StudentHomeView()
                case 1: ExploreView()
                case 2: ApplicationsView()
                case 3: MessagesView()
                default: ProfileView()
                }
            }
            .mcriDestinations()
            .mcriFollowThreadTargets(router, role: .student)
        }
        .environmentObject(router)
    }
}

private struct StudentTabViewPreview1: PreviewProvider {
    static var previews: some View {
        MCRIPreviewScreen(inNavigationStack: false) { StudentTabView() }
    }
}
