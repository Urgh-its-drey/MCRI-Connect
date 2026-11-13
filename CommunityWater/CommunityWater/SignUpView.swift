import SwiftUI

struct SignUpView: View {
    @EnvironmentObject private var auth: AuthStore
    @EnvironmentObject private var store: WaterStore
    let showSignIn: () -> Void
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmation = ""
    @State private var settings = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                if let email = auth.confirmationEmail {
                    AuthHeading(symbol: "envelope.badge", title: "Check your inbox.", subtitle: "If confirmation is required, a link will be sent to \(email). Open it, then return here to sign in. If you already have an account, sign in instead.")
                    AuthPrimaryButton(title: "Go to sign in", action: showSignIn)
                } else {
                    AuthHeading(symbol: "person.2.fill", title: "Stronger together.", subtitle: "Create your account and help your neighbours find water.")
                    fields.disabled(auth.busy)
                    AuthFeedback()
                    AuthPrimaryButton(title: "Create account", busy: auth.busy) {
                        Task {
                            let success = await auth.submit(action: .signUp, email: email, password: password, name: name, confirmation: confirmation, configuration: store.configuration)
                            if success { password = ""; confirmation = "" }
                        }
                    }
                    HStack(spacing: 5) {
                        Text("Already have an account?").foregroundStyle(.secondary)
                        Button("Sign in", action: showSignIn).fontWeight(.semibold)
                    }.font(.subheadline).frame(maxWidth: .infinity).disabled(auth.busy)
                    Text("Your email is used for your account. Water point reports are shared with your community.")
                        .font(.caption).foregroundStyle(.secondary)
                    if store.isDemo { Button("Connect your community in Settings") { settings = true }.font(.subheadline) }
                }
            }.padding(24)
        }.background(WaterTheme.paper).navigationTitle("Sign up").navigationBarTitleDisplayMode(.inline)
            .toolbar(.visible, for: .navigationBar)
            .sheet(isPresented: $settings) { SettingsView() }
            .onDisappear { password = ""; confirmation = "" }
    }

    private var fields: some View {
        VStack(spacing: 18) {
            AuthField(title: "Your name (optional)", symbol: "person") {
                TextField("What should we call you?", text: $name).textContentType(.name)
                    .onChange(of: name) { _, value in name = String(value.prefix(100)) }.accessibilityLabel("Your name")
            }
            AuthField(title: "Email address", symbol: "envelope") {
                TextField("you@example.com", text: $email).textContentType(.emailAddress).keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never).autocorrectionDisabled().accessibilityLabel("Email address")
            }
            AuthField(title: "Password", symbol: "lock") {
                SecureField("At least 8 characters", text: $password).textContentType(.newPassword).accessibilityLabel("Password")
            }
            AuthField(title: "Confirm password", symbol: "lock.shield") {
                SecureField("Enter your password again", text: $confirmation).textContentType(.newPassword).accessibilityLabel("Confirm password")
            }
        }
    }
}
