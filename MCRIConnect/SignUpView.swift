

import SwiftUI

struct SignUpView: View {
    @State private var fullName = ""
    @State private var emailAddress = ""
    @State private var password = ""
    @State private var hasAcceptedTerms = false
    @State private var showTerms = false

    var body: some View {
        ZStack(alignment: .topTrailing) {
            AppTheme.navy
                .ignoresSafeArea()

            Circle()
                .fill(AppTheme.blue.opacity(0.08))
                .frame(width: 430, height: 430)
                .offset(x: 165, y: -155)
                .accessibilityHidden(true)

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Start your journey")
                        .font(.title3.weight(.medium))
                        .padding(.bottom, 22)

                    SignUpBrandHeader()
                        .padding(.bottom, 30)

                    Text("Create account")
                        .font(.largeTitle.weight(.bold))
                        .padding(.bottom, 6)

                    Text("Build your profile and find your fit.")
                        .font(.title3)
                        .foregroundStyle(AppTheme.white.opacity(0.72))
                        .padding(.bottom, 34)

                    VStack(spacing: 22) {
                        SignUpTextField(
                            title: "Full name",
                            prompt: "Enter username",
                            text: $fullName,
                            contentType: .name,
                            keyboardType: .default,
                            capitalization: .words
                        )

                        SignUpTextField(
                            title: "Email address",
                            prompt: "enter email address",
                            text: $emailAddress,
                            contentType: .emailAddress,
                            keyboardType: .emailAddress,
                            capitalization: .never
                        )

                        SignUpSecureField(
                            title: "Create password",
                            prompt: " ",
                            text: $password
                        )
                    }
                    .padding(.bottom, 24)

                    HStack(alignment: .top, spacing: 14) {
                        Button {
                            hasAcceptedTerms.toggle()
                        } label: {
                            Image(
                                systemName: hasAcceptedTerms
                                    ? "checkmark.square.fill"
                                    : "square"
                            )
                            .font(.system(size: 27, weight: .medium))
                            .foregroundStyle(AppTheme.blue)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(
                            "Agree to the Terms and Privacy Policy"
                        )
                        .accessibilityValue(
                            hasAcceptedTerms ? "Selected" : "Not selected"
                        )

                        Button {
                            showTerms = true
                        } label: {
                            Text("I agree to the Terms and Privacy Policy")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(AppTheme.blue)
                                .multilineTextAlignment(.leading)
                                .underline()
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.bottom, 28)

                    Button {
                        createAccount()
                    } label: {
                        Text("Create account")
                            .font(.headline)
                            .foregroundStyle(AppTheme.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(
                                AppTheme.orange,
                                in: RoundedRectangle(cornerRadius: 16)
                            )
                    }
                    .buttonStyle(.plain)
                    .disabled(!hasAcceptedTerms)
                    .opacity(hasAcceptedTerms ? 1 : 0.5)
                    .padding(.bottom, 28)

                    HStack(spacing: 5) {
                        Text("Already have an account?")
                            .foregroundStyle(AppTheme.white.opacity(0.72))

                        NavigationLink("Sign in") {
                            LoginView()
                        }
                        .foregroundStyle(AppTheme.blue)
                    }
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 28)
                .frame(maxWidth: 560)
                .frame(maxWidth: .infinity)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .foregroundStyle(AppTheme.white)
        .toolbar(.hidden, for: .navigationBar)
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showTerms) {
            SignUpTermsView(
                hasAcceptedTerms: $hasAcceptedTerms
            )
        }
    }

    private func createAccount() {
        guard hasAcceptedTerms else { return }

        // Connect your authentication service here.
    }
}

private struct SignUpTermsView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var hasAcceptedTerms: Bool

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Terms and Conditions")
                        .font(.title.bold())

                    Text("Sample terms — replace before publishing.")
                        .font(.caption)
                        .foregroundStyle(AppTheme.white.opacity(0.72))

                    Text("""
                    1. Account information
                    Provide accurate information when creating your account.

                    2. Account security
                    Keep your password private and protect your account.

                    3. Respectful use
                    Treat other users respectfully. Harassment, fraud, and abusive content are prohibited.

                    4. Content
                    Only share content you have permission to use.
                    """)

                    Text("Privacy Policy")
                        .font(.title2.bold())

                    Text("""
                    Add your app’s privacy policy here. Explain what information you collect, why you collect it, who you share it with, how long you keep it, and how users can contact you or request deletion.
                    """)

                    Button {
                        hasAcceptedTerms = true
                        dismiss()
                    } label: {
                        Text("Agree and continue")
                            .font(.headline)
                            .foregroundStyle(AppTheme.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(
                                AppTheme.orange,
                                in: RoundedRectangle(cornerRadius: 16)
                            )
                    }
                    .buttonStyle(.plain)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(24)
            }
            .background(AppTheme.navy.ignoresSafeArea())
            .foregroundStyle(AppTheme.white)
            .navigationTitle("Terms & Privacy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundStyle(AppTheme.blue)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

private struct SignUpBrandHeader: View {
    var body: some View {
        HStack(spacing: 16) {
            Text("M")
                .font(.system(size: 30, weight: .heavy, design: .rounded))
                .foregroundStyle(AppTheme.white)
                .frame(width: 58, height: 58)
                .background(
                    AppTheme.orange,
                    in: RoundedRectangle(cornerRadius: 16)
                )

            Text("MCRI Connect")
                .font(.title.weight(.bold))
                .minimumScaleFactor(0.75)
                .lineLimit(1)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("MCRI Connect")
    }
}

private struct SignUpTextField: View {
    let title: LocalizedStringKey
    let prompt: LocalizedStringKey
    @Binding var text: String
    let contentType: UITextContentType?
    let keyboardType: UIKeyboardType
    let capitalization: TextInputAutocapitalization

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)

            TextField(text: $text, prompt: Text(prompt)) {
                Text(title)
            }
            .textContentType(contentType)
            .keyboardType(keyboardType)
            .textInputAutocapitalization(capitalization)
            .autocorrectionDisabled()
            .font(.body.weight(.medium))
            .padding(.horizontal, 18)
            .frame(minHeight: 58)
            .background(
                AppTheme.surface,
                in: RoundedRectangle(cornerRadius: 16)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(AppTheme.blue.opacity(0.28), lineWidth: 1)
            }
        }
    }
}

private struct SignUpSecureField: View {
    let title: LocalizedStringKey
    let prompt: LocalizedStringKey
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)

            SecureField(text: $text, prompt: Text(prompt)) {
                Text(title)
            }
            .textContentType(.newPassword)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .font(.body.weight(.medium))
            .padding(.horizontal, 18)
            .frame(minHeight: 58)
            .background(
                AppTheme.surface,
                in: RoundedRectangle(cornerRadius: 16)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(AppTheme.blue.opacity(0.28), lineWidth: 1)
            }
        }
    }
}

#Preview {
    NavigationStack {
        SignUpView()
    }
}
