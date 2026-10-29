import SwiftUI

struct AuthView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var showPassword = false

    var body: some View {
        ZStack {
            Brand.navy.ignoresSafeArea()

            Circle()
                .fill(.white.opacity(0.05))
                .frame(width: 300, height: 300)
                .offset(x: 130, y: -300)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Welcome back")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white)

                    HStack(spacing: 12) {
                        Text("M")
                            .font(.title.bold())
                            .foregroundStyle(.white)
                            .frame(width: 54, height: 54)
                            .background(Brand.orange, in: RoundedRectangle(cornerRadius: 16))

                        Text("MCRI Connect")
                            .font(.title.bold())
                            .foregroundStyle(.white)
                    }
                    .padding(.top, 22)

                    Text("Sign in")
                        .font(.system(size: 38, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.top, 34)

                    Text("Continue your internship journey.")
                        .font(.body)
                        .foregroundStyle(Brand.mutedText)
                        .padding(.top, 4)

                    fieldLabel("Email address")
                        .padding(.top, 34)

                    TextField("you@example.com", text: $email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .textFieldStyle(.plain)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 18)
                        .frame(height: 54)
                        .background(Brand.field, in: RoundedRectangle(cornerRadius: 16))

                    fieldLabel("Password")
                        .padding(.top, 22)

                    HStack {
                        Group {
                            if showPassword {
                                TextField("Password", text: $password)
                            } else {
                                SecureField("Password", text: $password)
                            }
                        }
                        .foregroundStyle(.white)

                        Button(showPassword ? "Hide" : "Show") {
                            showPassword.toggle()
                        }
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(Brand.cyan)
                    }
                    .padding(.horizontal, 18)
                    .frame(height: 54)
                    .background(Brand.field, in: RoundedRectangle(cornerRadius: 16))

                    Button("Forgot password?") {
                        print("Forgot password tapped")
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Brand.cyan)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.top, 12)

                    Button {
                        print("Sign in tapped")
                    } label: {
                        Text("Sign in")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .foregroundStyle(.white)
                            .background(Brand.orange, in: RoundedRectangle(cornerRadius: 18))
                    }
                    .buttonStyle(PressableStyle())
                    .padding(.top, 32)

                    Text("Don’t have an account?")
                        .font(.subheadline)
                        .foregroundStyle(Brand.mutedText)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 28)

                    Button {
                        print("Create account tapped")
                    } label: {
                        Text("Create account")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .foregroundStyle(Brand.cyan)
                            .overlay {
                                RoundedRectangle(cornerRadius: 18)
                                    .stroke(Brand.cyan, lineWidth: 2)
                            }
                    }
                    .padding(.top, 14)

                    Text("By continuing, you agree to our Terms and Privacy Policy.")
                        .font(.caption)
                        .foregroundStyle(Brand.mutedText)
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)
                        .padding(.top, 34)
                }
                .padding(.horizontal, 24)
                .padding(.top, 28)
                .padding(.bottom, 28)
                .frame(maxWidth: 460)
            }
        }
    }

    private func fieldLabel(_ text: String) -> some View {
        Text(text)
            .font(.subheadline.weight(.bold))
            .foregroundStyle(.white)
            .padding(.bottom, 8)
    }
}

#Preview {
    AuthView()
}
