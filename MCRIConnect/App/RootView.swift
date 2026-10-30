import SwiftUI

struct RootView: View {
    @EnvironmentObject private var auth: AuthService
    @EnvironmentObject private var store: AppStore

    @State private var isSplashVisible = true

    var body: some View {
        ZStack {
            MCRITheme.background.ignoresSafeArea()

            // The role comes from the server, so until it lands the only safe screen is the
            // launch one. Nothing here decides which workspace opens.
            if auth.isResolvingProfile || isSplashVisible {
                SplashView()
            } else if !auth.isSignedIn {
                WelcomeView()
            } else if auth.needsOnboarding {
                StudentOnboardingView()
            } else {
                workspace
            }
        }
        .animation(.easeInOut(duration: 0.25), value: auth.isSignedIn)
        .animation(.easeInOut(duration: 0.25), value: auth.needsOnboarding)
        .onOpenURL { url in
            Task { await auth.handleResetLink(url) }
        }
        .sheet(isPresented: resetSheet) {
            NewPasswordSheet()
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
                .interactiveDismissDisabled()
                .preferredColorScheme(.dark)
        }
        .task {
            #if DEBUG
            if DebugLaunch.usesSampleData {
                store.previewAsSignedIn(role: DebugLaunch.role ?? .student)
            }
            #endif
            try? await Task.sleep(nanoseconds: 1_200_000_000)
            isSplashVisible = false
            await store.load()
        }
        .mcriToast($store.toast)
    }

    /// Pulling the sheet down counts as abandoning the reset, and a recovery session left in
    /// the Keychain is access the person never agreed to keep.
    private var resetSheet: Binding<Bool> {
        Binding(get: { auth.isAwaitingNewPassword },
                set: { presented in if !presented { auth.cancelPasswordReset() } })
    }

    @ViewBuilder private var workspace: some View {
        switch auth.session.role {
        case .student: StudentTabView()
        case .employer: EmployerTabView()
        case .programManager: ProgramManagerTabView()
        }
    }
}

private struct RootViewPreview1: PreviewProvider {
    static var previews: some View {
    MCRIPreviewScreen(inNavigationStack: false) { RootView() }
}
}
