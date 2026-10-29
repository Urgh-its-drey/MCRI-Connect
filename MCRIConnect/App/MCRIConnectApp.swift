import SwiftUI

@main
struct MCRIConnectApp: App {
    @StateObject private var auth = AuthService.shared
    @StateObject private var store = AppStore.shared

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(auth)
                .environmentObject(store)
                .preferredColorScheme(.dark)
                .tint(MCRITheme.primaryAction)
        }
    }
}
