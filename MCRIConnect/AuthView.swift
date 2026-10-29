import SwiftUI

struct AuthView: View {
    var onSignIn: (@MainActor (String, String) async throws -> Void)? = nil
   
    var onSignUp: (@MainActor (String, String, String, UserRole) async throws -> Void)? = nil
    var onForgotPassword: (() -> Void)? = nil
    @State private var pendingWorkspace: AuthWorkspace?
    @State private var workspace: AuthWorkspace?
    @State private var email = ""
    @State private var password = ""
    @State private var showPassword = false
    @State private var showSignUp = false
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    var body: some View {
        ZStack {
            Brand.navy.ignoresSafeArea()
            Circle()
                .fill(.white.opacity(0.05))
                .frame(width: 300, height: 300)
                .offset(x: 130, y: -300)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Welcome back")
                        .font(.subheadline.weight(.medium))
                    HStack(spacing: 12) {
                        Text("M")
                            .font(.title.bold())
                            .frame(width: 54, height: 54)
                            .background(Brand.orange, in: RoundedRectangle(cornerRadius: 16))
                            .accessibilityHidden(true)
                        Text("MCRI Connect").font(.title.bold())
                    }
                    .padding(.top, 22)
                    Text("Sign in")
                        .font(.system(size: 38, weight: .bold))
                        .padding(.top, 34)
                        .accessibilityAddTraits(.isHeader)
                    if onSignUp == nil {
                        Text("Preview only · Account service is not connected")
                            .font(.caption).foregroundStyle(Brand.orange).padding(.top, 10)
                    }
                    Text("Continue your internship journey.")
                        .foregroundStyle(Brand.mutedText)
                        .padding(.top, 4)
                    AuthFieldLabel(title: "Email address").padding(.top, 34)
                    TextField("you@example.com", text: $email)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .accessibilityLabel("Email address")
                        .modifier(AuthFieldStyle())
                        .disabled(isSubmitting)
                    AuthFieldLabel(title: "Password").padding(.top, 22)
                    AuthPasswordField(password: $password, isVisible: $showPassword, isNew: false)
                        .disabled(isSubmitting)
                    Button("Forgot password?") {
                        if let onForgotPassword { onForgotPassword() }
                        else { errorMessage = "Password reset is not connected yet." }
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Brand.cyan)
                    .frame(maxWidth: .infinity, minHeight: 44, alignment: .trailing)
                    .disabled(isSubmitting)
                    if let errorMessage {
                        Text(errorMessage).font(.footnote).padding(.top, 12)
                    }
                    Button(action: signIn) {
                        HStack {
                            if isSubmitting { ProgressView().tint(.white) }
                            Text(isSubmitting ? "Signing in…" : "Sign in")
                        }
                        .font(.headline)
                        .frame(maxWidth: .infinity, minHeight: 54)
                        .background(Brand.orange, in: RoundedRectangle(cornerRadius: 18))
                    }
                    .disabled(isSubmitting)
                    .padding(.top, 24)
                    Text("Don’t have an account?")
                        .font(.subheadline)
                        .foregroundStyle(Brand.mutedText)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 28)
                    Button { showSignUp = true } label: {
                        Text("Create account")
                            .font(.headline)
                            .frame(maxWidth: .infinity, minHeight: 52)
                            .foregroundStyle(Brand.cyan)
                            .overlay {
                                RoundedRectangle(cornerRadius: 18)
                                    .strokeBorder(Brand.cyan, lineWidth: 2)
                            }
                            .contentShape(RoundedRectangle(cornerRadius: 18))
                    }
                    
                    .disabled(isSubmitting)
                                .padding(.top, 14)
                                Text("By continuing, you agree to our Terms and Privacy Policy.")
                                    .font(.caption)
                                    .foregroundStyle(Brand.mutedText)
                                    .frame(maxWidth: .infinity)
                                    .multilineTextAlignment(.center)
                                    .padding(.top, 34)
                            }
                            .padding(.horizontal, 24)
                            .padding(.vertical, 28)
                            .frame(maxWidth: 460)
                            .frame(maxWidth: .infinity)
                        }
                        .scrollDismissesKeyboard(.interactively)
                    }
                    .foregroundStyle(.white)
                    .buttonStyle(.plain)
                    .preferredColorScheme(.dark)
                    .sheet(isPresented: $showSignUp, onDismiss: openCreatedWorkspace) {
                        AuthSignUpSheet(onSignUp: onSignUp) { fullName, role in
                            pendingWorkspace = AuthWorkspace(fullName: fullName, role: role)
                            showSignUp = false
                        }
                        .presentationDetents([.large])
                        .presentationDragIndicator(.visible)
                        .preferredColorScheme(.dark)
                    }
                    .fullScreenCover(item: $workspace) { account in
                        destination(for: account)
                    }
                }
                private func openCreatedWorkspace() {
                    guard let created = pendingWorkspace else { return }
                    pendingWorkspace = nil
                    workspace = created
                }
                @ViewBuilder
                private func destination(for account: AuthWorkspace) -> some View {
                    switch account.role {
                    case .student:
                        StudentDashboardView()
                    case .employer:
                        EmployerPipelineView()
                    case .programManager:
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Program manager").font(.title2.bold())
                            Text("Welcome, \(account.fullName)")
                            Text("Your workspace is not available yet.")
                            Button("Back") { workspace = nil }
                            Spacer()
                        }
                        .padding(24)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                        .background(Brand.navy.ignoresSafeArea())
                        .foregroundStyle(.white)
                    }
                }

                private func signIn() {
                    guard !isSubmitting else { return }
                    errorMessage = nil
                    let address = email.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard isValidAuthEmail(address), !password.isEmpty else {
                        errorMessage = "Enter a valid email address and your password."
                        return
                    }
                    guard let onSignIn else {
                        errorMessage = "Connect sign-in to your authentication service to continue."
                        return
                    }
                    let submittedPassword = password
                    isSubmitting = true
                    Task { @MainActor in
                        defer { isSubmitting = false }
                        do {
                            try await onSignIn(address, submittedPassword)
                            password = ""
                        } catch { errorMessage = error.localizedDescription }
                    }
                }
            }
            private struct AuthWorkspace: Identifiable {
                let id = UUID()
                let fullName: String
                let role: UserRole
            }
private struct AuthSignUpSheet: View {
    let onSignUp: (@MainActor (String, String, String, UserRole) async throws -> Void)?
    let onCompleted: (String, UserRole) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var fullName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var showPassword = false
    @State private var role: UserRole = .student
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    var body: some View {
        ZStack {
            Brand.navy.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    HStack(alignment: .top) {
                        Text("Create account")
                            .font(.system(size: 30, weight: .bold))
                            .accessibilityAddTraits(.isHeader)
                        Spacer()
                        Button { dismiss() } label: {
                            Image(systemName: "xmark").frame(width: 44, height: 44)
                        }
                        .accessibilityLabel("Close sign-up")
                        .disabled(isSubmitting)
                    }
                    
                    if onSignUp == nil {
                        Text("Preview only · No real account will be created")
                            .font(.caption).foregroundStyle(Brand.orange).padding(.top, 10)
                    }
                    Text("Students, employers and programme managers each get their own workspace.")
                        .foregroundStyle(Brand.mutedText)
                        .padding(.top, 8)
                    AuthFieldLabel(title: "FULL NAME").padding(.top, 26)
                    TextField("Your full name", text: $fullName)
                        .textContentType(.name)
                        .textInputAutocapitalization(.words)
                        .accessibilityLabel("Full name")
                        .modifier(AuthFieldStyle())
                        .disabled(isSubmitting)
                    AuthFieldLabel(title: "EMAIL ADDRESS").padding(.top, 20)
                    TextField("you@example.com", text: $email)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .accessibilityLabel("Email address")
                        .modifier(AuthFieldStyle())
                        .disabled(isSubmitting)
                    AuthFieldLabel(title: "PASSWORD").padding(.top, 20)
                    AuthPasswordField(password: $password, isVisible: $showPassword, isNew: true)
                        .disabled(isSubmitting)
                    AuthFieldLabel(title: "I AM JOINING AS").padding(.top, 20)
                    ViewThatFits(in: .horizontal) {
                        HStack(spacing: 8) { roleChoices }
                        VStack(alignment: .leading, spacing: 8) { roleChoices }
                    }
                    .disabled(isSubmitting)
                    if let errorMessage {
                        Text(errorMessage).font(.footnote).padding(.top, 16)
                    }
                    Button(action: signUp) {
                        HStack {
                            if isSubmitting { ProgressView().tint(.white) }
                            else { Image(systemName: "arrow.right") }
                            Text(isSubmitting ? "Creating account…" : "Create account")
                        }
                        .font(.headline)
                        .frame(maxWidth: .infinity, minHeight: 54)
                        .background(Brand.orange, in: RoundedRectangle(cornerRadius: 18))
                    }
                    .disabled(isSubmitting)
                    .padding(.top, 24)
                    Button { dismiss() } label: {
                        Text("Already registered? Log in →")
                            .foregroundStyle(Brand.cyan)
                            .frame(minHeight: 44)
                    }
                    .disabled(isSubmitting)
                    .padding(.top, 18)
                }
                .padding(24)
                .padding(.top, 12)
                .frame(maxWidth: 460)
                .frame(maxWidth: .infinity)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .foregroundStyle(.white)
        .buttonStyle(.plain)
        .interactiveDismissDisabled(isSubmitting)
    }
    private var roleChoices: some View {
        ForEach(UserRole.allCases) { option in
            Button { role = option } label: {
                HStack(spacing: 5) {
                    Image(systemName: role == option ? "checkmark" : "plus")
                    Text(option == .programManager ? "Manager" : option.rawValue)
                }
                .font(.subheadline.weight(.semibold))
                .fixedSize(horizontal: true, vertical: false)
                .foregroundStyle(role == option ? Brand.navy : Brand.cyan)
                .padding(.horizontal, 13)
                .frame(minHeight: 44)
                .background(role == option ? Brand.orange : Brand.field, in: Capsule())
                .overlay {
                    Capsule().strokeBorder(role == option ? Brand.orange : Brand.cyan, lineWidth: 1)
                }
                .contentShape(Capsule())
            }
            .accessibilityLabel(option.rawValue)
            .accessibilityAddTraits(role == option ? .isSelected : [])
        }
    }
    
    private func signUp() {
            guard !isSubmitting else { return }
            errorMessage = nil
            let name = fullName.trimmingCharacters(in: .whitespacesAndNewlines)
            let address = email.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !name.isEmpty else {
                errorMessage = "Please enter your full name."
                return
            }
            guard isValidAuthEmail(address) else {
                errorMessage = "Please enter a valid email address."
                return
            }
            guard password.count >= 6 else {
                errorMessage = "Use a password with at least 6 characters."
                return
            }
            let submittedRole = role
            let submittedPassword = password
            isSubmitting = true
            Task { @MainActor in
                defer { isSubmitting = false }
                do {
                    if let onSignUp {
                      
                        try await onSignUp(name, address, submittedPassword, submittedRole)
                        try Task.checkCancellation()
                    }
                    password = ""
                    onCompleted(name, submittedRole)
                } catch { errorMessage = error.localizedDescription }
            }
        }
    }
    private struct AuthFieldLabel: View {
        let title: String
        var body: some View {
            Text(title)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.white)
                .padding(.bottom, 8)
        }
    }
    private struct AuthFieldStyle: ViewModifier {
        func body(content: Content) -> some View {
            content
                .textFieldStyle(.plain)
                .foregroundStyle(.white)
                .padding(.horizontal, 18)
                .frame(minHeight: 54)
                .background(Brand.field, in: RoundedRectangle(cornerRadius: 16))
        }
    }
    private struct AuthPasswordField: View {
        @Binding var password: String
        @Binding var isVisible: Bool
        let isNew: Bool
        var body: some View {
            HStack {
                Group {
                    if isVisible {
                        TextField(isNew ? "At least 6 characters" : "Password", text: $password)
                    } else {
                        SecureField(isNew ? "At least 6 characters" : "Password", text: $password)
                    }
                }
                .textContentType(isNew ? .newPassword : .password)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .accessibilityLabel("Password")
                Button(isVisible ? "Hide" : "Show") { isVisible.toggle() }
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Brand.cyan)
                    .frame(minWidth: 44, minHeight: 44)
                    .accessibilityLabel(isVisible ? "Hide password" : "Show password")
            }
            .modifier(AuthFieldStyle())
        }
    }
    private func isValidAuthEmail(_ address: String) -> Bool {
        let parts = address.split(separator: "@", omittingEmptySubsequences: false)
        return parts.count == 2 && !parts[0].isEmpty && parts[1].contains(".")
            && !parts[1].hasPrefix(".") && !parts[1].hasSuffix(".")
            && !address.contains(where: { $0.isWhitespace })
    }
    struct AuthView_Previews: PreviewProvider {
        static var previews: some View { AuthView() }
    }

