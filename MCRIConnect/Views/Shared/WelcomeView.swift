import SwiftUI

struct WelcomeView: View {
    @EnvironmentObject private var auth: AuthService
    @StateObject private var viewModel = WelcomeViewModel()

    private var roles: Int { max(SampleData.internships.count, 121) }
    private var employers: Int { SampleData.companies.count }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: MCRITheme.Spacing.s6) {
                HStack(spacing: MCRITheme.Spacing.s3) {
                    MCRIBrandMark(size: 40)
                    VStack(alignment: .leading, spacing: 1) {
                        Text("MCRI Connect").font(.mcriCardTitle).foregroundStyle(MCRITheme.textPrimary)
                        Text("Internship placement").font(.mcriCaption2).foregroundStyle(MCRITheme.textTertiary)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 1) {
                        Text("\(roles) open roles")
                            .font(.mcriCaption.weight(.bold)).foregroundStyle(MCRITheme.primaryAction)
                        Text("\(employers) verified employers")
                            .font(.mcriCaption2).foregroundStyle(MCRITheme.textTertiary)
                    }
                }
                .padding(.top, MCRITheme.Spacing.s2)

                VStack(alignment: .leading, spacing: 6) {
                    Text("Connect your skills")
                        .font(.mcriDisplay)
                        .foregroundStyle(MCRITheme.textPrimary)
                    Text("to real opportunities.")
                        .font(.mcriDisplay)
                        .foregroundStyle(MCRITheme.primaryAction)
                }
                .fixedSize(horizontal: false, vertical: true)

                Text("One profile scores you against every internship in the programme — and shows exactly "
                     + "why a match is strong or weak.")
                    .font(.mcriBody)
                    .foregroundStyle(MCRITheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                MCRICard(padding: MCRITheme.Spacing.s3) {
                    VStack(spacing: 0) {
                        valueRow(symbol: "target", tone: MCRITheme.primaryAction,
                                 title: "Matches you can explain",
                                 detail: "Skills, interests and logistics — scored separately")
                        divider
                        valueRow(symbol: "checkmark.seal.fill", tone: MCRITheme.secondaryAction,
                                 title: "Verified employers only",
                                 detail: "\(employers) partners who hire from this cohort")
                        divider
                        valueRow(symbol: "chart.line.uptrend.xyaxis", tone: MCRITheme.accent,
                                 title: "Every application tracked",
                                 detail: "From submitted to offer, with the next action")
                    }
                }

                VStack(spacing: MCRITheme.Spacing.s3) {
                    MCRIButton(title: "Create account", symbol: "arrow.right") {
                        viewModel.begin(.signUp)
                    }
                    MCRISecondaryButton(title: "Log in", symbol: "person.crop.circle") {
                        viewModel.begin(.signIn)
                    }
                    MCRILinkButton(title: "Forgot password?") {
                        auth.authError = "We would email a reset link to your address."
                    }
                }

                VStack(alignment: .leading, spacing: MCRITheme.Spacing.s3) {
                    MCRISectionHeader(title: "Continue as")
                    HStack(spacing: MCRITheme.Spacing.s2) {
                        ForEach(UserRole.allCases) { role in
                            Button {
                                auth.continueAs(role)
                            } label: {
                                VStack(spacing: 6) {
                                    Image(systemName: role.glyph)
                                        .font(.system(size: 17, weight: .semibold))
                                    Text(role.welcomeTitle)
                                        .font(.mcriCaption2.weight(.semibold))
                                        .multilineTextAlignment(.center)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.7)
                                }
                                .foregroundStyle(MCRITheme.textSecondary)
                                .frame(maxWidth: .infinity)
                                .frame(height: MCRITheme.Metrics.minTapTarget + 14)
                                .background(MCRITheme.surface, in: RoundedRectangle(cornerRadius: MCRITheme.Radius.control,
                                                                                   style: .continuous))
                                .overlay(RoundedRectangle(cornerRadius: MCRITheme.Radius.control, style: .continuous)
                                    .strokeBorder(MCRITheme.border, lineWidth: 1))
                            }
                            .buttonStyle(MCRIPressStyle())
                        }
                    }
                }

                Text("By continuing you agree to the placement code of conduct and the programme "
                     + "privacy notice. Your profile is only shared with employers you apply to.")
                    .font(.mcriCaption2)
                    .foregroundStyle(MCRITheme.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.bottom, MCRITheme.Spacing.s2)
            }
            .padding(.horizontal, MCRITheme.Spacing.screenMargin)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .scrollIndicators(.hidden)
        .background(MCRITheme.background.ignoresSafeArea())
        .sheet(item: $viewModel.openForm) { form in
            AuthFormSheet(viewModel: viewModel, form: form)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
                .preferredColorScheme(.dark)
        }
    }

    private var divider: some View {
        Rectangle().fill(MCRITheme.divider).frame(height: 1).padding(.vertical, 2)
    }

    private func valueRow(symbol: String, tone: Color, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: MCRITheme.Spacing.s3) {
            Image(systemName: symbol)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(tone)
                .frame(width: 22)
                .padding(.top, 1)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.mcriCardTitle).foregroundStyle(MCRITheme.textPrimary)
                Text(detail).font(.mcriFootnote).foregroundStyle(MCRITheme.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, MCRITheme.Spacing.s3)
    }
}

private struct AuthFormSheet: View {
    @ObservedObject var viewModel: WelcomeViewModel
    var form: WelcomeViewModel.Form

    var body: some View {
        VStack(alignment: .leading, spacing: MCRITheme.Spacing.s5) {
            VStack(alignment: .leading, spacing: 4) {
                Text(form == .signUp ? "Create your account" : "Welcome back")
                    .font(.mcriTitle)
                    .foregroundStyle(MCRITheme.textPrimary)
                Text(form == .signUp
                     ? "Students, employers and programme managers each get their own workspace."
                     : "Log in with the address you registered with your institution.")
                    .font(.mcriFootnote)
                    .foregroundStyle(MCRITheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.top, MCRITheme.Spacing.s6)

            VStack(alignment: .leading, spacing: MCRITheme.Spacing.s4) {
                if form == .signUp {
                    MCRIField(label: "Full name", placeholder: "Thando Mthembu", text: $viewModel.fullName,
                              keyboard: .namePhonePad, autocapitalization: .words)
                }

                MCRIField(label: "Institution email", placeholder: "you@institution.ac.za",
                          text: $viewModel.email, keyboard: .emailAddress)

                MCRIField(label: "Password", placeholder: "At least 6 characters", text: $viewModel.password,
                          isSecure: true, errorMessage: viewModel.errorText)

                if form == .signUp {
                    VStack(alignment: .leading, spacing: MCRITheme.Spacing.s2) {
                        Text("I am joining as").mcriLabelStyle()
                        HStack(spacing: MCRITheme.Spacing.s2) {
                            ForEach(UserRole.allCases) { role in
                                MCRIFilterChip(title: role.welcomeTitle,
                                               isSelected: viewModel.role == role) {
                                    viewModel.role = role
                                }
                            }
                        }
                    }
                }

                if let error = viewModel.errorText, !error.isEmpty {
                    HStack(spacing: MCRITheme.Spacing.s2) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundStyle(MCRITheme.blocked)
                        Text(error).font(.mcriCaption).foregroundStyle(MCRITheme.textSecondary)
                    }
                }

                MCRIButton(title: form == .signUp ? "Create account" : "Log in",
                           symbol: "arrow.right",
                           isDisabled: !viewModel.canSubmit,
                           isLoading: viewModel.isBusy) {
                    Task { await viewModel.submit() }
                }

                MCRILinkButton(title: form == .signUp ? "Already registered? Log in" : "New here? Create account",
                               symbol: "arrow.right") {
                    viewModel.begin(form == .signUp ? .signIn : .signUp)
                }
            }

            Spacer()
        }
        .padding(.horizontal, MCRITheme.Spacing.screenMargin)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(MCRITheme.background)
    }
}

private struct WelcomeViewPreview1: PreviewProvider {
    static var previews: some View {
    MCRIPreviewScreen(inNavigationStack: false) { WelcomeView() }
}
}
