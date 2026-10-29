import SwiftUI

/// The student workspace: Home, Explore, Applications, Messages, Profile.
struct StudentTabView: View {
    @EnvironmentObject private var store: AppStore
    @StateObject private var router = Router()

    private var items: [MCRITabBar.Item] {
        [
            MCRITabBar.Item(title: "Home", symbol: "house.fill"),
            MCRITabBar.Item(title: "Explore", symbol: "magnifyingglass"),
            MCRITabBar.Item(title: "Applications", symbol: "briefcase.fill",
                            badge: store.activeApplications),
            MCRITabBar.Item(title: "Messages", symbol: "bubble.left.fill",
                            badge: store.unreadMessages),
            MCRITabBar.Item(title: "Profile", symbol: "person.fill"),
        ]
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
        }
        .environmentObject(router)
    }
}

private struct StudentTabViewPreview1: PreviewProvider {
    static var previews: some View {
    MCRIPreviewScreen(inNavigationStack: false) { StudentTabView() }
}
}
