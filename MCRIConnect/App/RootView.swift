import SwiftUI

struct RootView: View {
    @EnvironmentObject private var auth: AuthService
    @EnvironmentObject private var store: AppStore

    @State private var isSplashVisible = true

    var body: some View {
        ZStack {
            MCRITheme.background.ignoresSafeArea()

            switch auth.session.role {
            case .student where auth.isSignedIn:
                if auth.needsOnboarding {
                    StudentOnboardingView()
                } else {
                    StudentTabView()
                }
            case .employer where auth.isSignedIn:
                EmployerTabView()
            case .programManager where auth.isSignedIn:
                ProgramManagerTabView()
            default:
                WelcomeView()
            }

            if isSplashVisible {
                SplashView()
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .animation(.easeInOut(duration: 0.4), value: isSplashVisible)
        .animation(.easeInOut(duration: 0.25), value: auth.isSignedIn)
        .animation(.easeInOut(duration: 0.25), value: auth.needsOnboarding)
        .task {
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            isSplashVisible = false
            await store.load()
        }
        .mcriToast($store.toast)
    }
}

private struct RootViewPreview1: PreviewProvider {
    static var previews: some View {
    MCRIPreviewScreen(inNavigationStack: false) { RootView() }
}
}
