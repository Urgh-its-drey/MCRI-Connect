import SwiftUI

struct WelcomeView: View {
    @EnvironmentObject private var auth: AuthService
    @EnvironmentObject private var store: AppStore
    @StateObject private var viewModel = WelcomeViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: MCRITheme.Spacing.s6) {
                header

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

                VStack(spacing: MCRITheme.Spacing.s3) {
                    MCRIButton(title: "Create account", symbol: "arrow.right") {
                        viewModel.begin(.signUp)
                    }
                    MCRISecondaryButton(title: "Log in", symbol: "person.crop.circle") {
                        viewModel.begin(.signIn)
                    }
                    MCRILinkButton(title: "Forgot password?") {
                        viewModel.begin(.reset)
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

    /// Live counts come from the snapshot, so the welcome screen cannot quote a number the
    /// programme no longer has.
    private var header: some View {
        HStack(spacing: MCRITheme.Spacing.s3) {
            MCRIBrandMark(size: 40)
            VStack(alignment: .leading, spacing: 1) {
                Text("MCRI Connect").font(.mcriCardTitle).foregroundStyle(MCRITheme.textPrimary)
                Text("Internship placement").font(.mcriCaption2).foregroundStyle(MCRITheme.textTertiary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 1) {
                Text("\(store.publishedRoles.count) open roles")
                    .font(.mcriCaption.weight(.bold)).foregroundStyle(MCRITheme.primaryAction)
                Text("\(store.verifiedCompanies.count) verified "
                     + (store.verifiedCompanies.count == 1 ? "employer" : "employers"))
                    .font(.mcriCaption2).foregroundStyle(MCRITheme.textTertiary)
            }
        }
        .padding(.top, MCRITheme.Spacing.s2)
    }
}

private struct AuthFormSheet: View {
    @ObservedObject var viewModel: WelcomeViewModel
    var form: WelcomeViewModel.Form

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: MCRITheme.Spacing.s5) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(form.title)
                        .font(.mcriTitle)
                        .foregroundStyle(MCRITheme.textPrimary)
                    Text(form.subtitle)
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

                    if form != .reset {
                        MCRIField(label: "Password", placeholder: passwordPlaceholder,
                                  text: $viewModel.password, isSecure: true)
                    }

                    if form == .signUp {
                        rolePicker
                        if viewModel.needsCompanyName {
                            MCRIField(label: "Company name", placeholder: "Orbit Labs (Pty) Ltd",
                                      text: $viewModel.companyName, autocapitalization: .words)
                        }
                    }

                    statusLine

                    MCRIButton(title: form.actionTitle,
                               symbol: "arrow.right",
                               isDisabled: !viewModel.canSubmit,
                               isLoading: viewModel.isBusy) {
                        Task { await viewModel.submit() }
                    }

                    if form != .reset {
                        MCRILinkButton(title: form == .signUp ? "Already registered? Log in" : "New here? Create account",
                                       symbol: "arrow.right") {
                            viewModel.begin(form == .signUp ? .signIn : .signUp)
                        }
                    } else {
                        MCRILinkButton(title: "Back to log in", symbol: "arrow.left") {
                            viewModel.begin(.signIn)
                        }
                    }
                }
            }
            .padding(.horizontal, MCRITheme.Spacing.screenMargin)
            .padding(.bottom, MCRITheme.Spacing.s8)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(MCRITheme.background)
    }

    private var passwordPlaceholder: String {
        form == .signUp ? "At least 8 characters" : "Your password"
    }

    private var rolePicker: some View {
        VStack(alignment: .leading, spacing: MCRITheme.Spacing.s2) {
            Text("I am joining as").mcriLabelStyle()
            HStack(spacing: MCRITheme.Spacing.s2) {
                ForEach(UserRole.allCases) { role in
                    MCRIFilterChip(title: role.welcomeTitle, isSelected: viewModel.role == role) {
                        viewModel.role = role
                    }
                }
            }
            Text(roleHint)
                .font(.mcriCaption2)
                .foregroundStyle(MCRITheme.textTertiary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var roleHint: String {
        switch viewModel.role {
        case .student:
            return "Your institution's email links you to your cohort and adviser."
        case .employer:
            return "You hire as a company. A programme manager verifies it before your roles reach students."
        case .programManager:
            return "Managers sign up with an MCRI staff address. Other addresses are held pending review."
        }
    }

    @ViewBuilder private var statusLine: some View {
        if let error = viewModel.errorText, !error.isEmpty {
            HStack(alignment: .top, spacing: MCRITheme.Spacing.s2) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(MCRITheme.blocked)
                Text(error).font(.mcriCaption).foregroundStyle(MCRITheme.textSecondary)
            }
        } else if let notice = viewModel.noticeText, !notice.isEmpty {
            HStack(alignment: .top, spacing: MCRITheme.Spacing.s2) {
                Image(systemName: "envelope.fill")
                    .font(.caption)
                    .foregroundStyle(MCRITheme.secondaryAction)
                Text(notice).font(.mcriCaption).foregroundStyle(MCRITheme.textSecondary)
            }
        }
    }
}

private struct WelcomeViewPreview1: PreviewProvider {
    static var previews: some View {
        MCRIPreviewScreen(inNavigationStack: false) { WelcomeView() }
    }
}
