import SwiftUI

struct SignInView: View {
    @EnvironmentObject private var auth: AuthStore
    @EnvironmentObject private var store: WaterStore
    let showSignUp: () -> Void
    @State private var email = ""
    @State private var password = ""
    @State private var revealPassword = false
    @State private var settings = false
    @FocusState private var focus: Field?
    private enum Field { case email, password }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                AuthHeading(symbol: "person.crop.circle.badge.checkmark", title: "Welcome back.", subtitle: "Sign in and keep your community flowing.")
                VStack(spacing: 20) {
                    AuthField(title: "Email address", symbol: "envelope") {
                        TextField("you@example.com", text: $email).textContentType(.username)
                            .keyboardType(.emailAddress).textInputAutocapitalization(.never).autocorrectionDisabled()
                            .focused($focus, equals: .email).submitLabel(.next).onSubmit { focus = .password }
                            .accessibilityLabel("Email address")
                    }
                    AuthField(title: "Password", symbol: "lock") {
                        Group {
                            if revealPassword { TextField("Your password", text: $password) }
                            else { SecureField("Your password", text: $password) }
                        }.textContentType(.password).textInputAutocapitalization(.never).autocorrectionDisabled()
                            .focused($focus, equals: .password).submitLabel(.go).onSubmit { submit() }
                            .accessibilityLabel("Password")
                        Button { revealPassword.toggle() } label: { Image(systemName: revealPassword ? "eye.slash" : "eye") }
                            .accessibilityLabel(revealPassword ? "Hide password" : "Show password")
                    }
                }.disabled(auth.busy)
                AuthFeedback()
                AuthPrimaryButton(title: "Sign in", busy: auth.busy) { submit() }
                HStack(spacing: 5) {
                    Text("New to Community Water?").foregroundStyle(.secondary)
                    Button("Sign up", action: showSignUp).fontWeight(.semibold)
                }.font(.subheadline).frame(maxWidth: .infinity).disabled(auth.busy)
                if store.isDemo {
                    Button("Connect your community in Settings") { settings = true }.font(.subheadline)
                }
            }.padding(24)
        }.background(WaterTheme.paper).navigationTitle("Sign in").navigationBarTitleDisplayMode(.inline)
            .toolbar(.visible, for: .navigationBar)
            .sheet(isPresented: $settings) { SettingsView() }
            .onDisappear { password = "" }
    }

    private func submit() {
        focus = nil
        Task {
            let success = await auth.submit(action: .signIn, email: email, password: password, configuration: store.configuration)
            if success { password = "" }
        }
    }
}
