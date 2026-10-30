import SwiftUI

/// The account every workspace shares: the name employers see, the password reset path,
/// what the app holds about you, and the deletion control App Store rule 5.1.1(v) requires.
struct AccountView: View {
    @EnvironmentObject private var store: AppStore
    @EnvironmentObject private var auth: AuthService
    @EnvironmentObject private var router: Router

    @State private var nameDraft = ""
    @State private var isDeleting = false
    @State private var showDeletePrompt = false
    @State private var showSignOutPrompt = false

    var body: some View {
        MCRIPage {
            identityCard
            nameCard

            MCRISectionHeader(title: "Security")
            securityCard

            MCRISectionHeader(title: "Your data")
            privacyCard

            MCRISectionHeader(title: "Session")
            signOutCard

            MCRISectionHeader(title: "Danger zone")
            deletionCard
        }
        .mcriScreen(title: "Account", hidesTitle: false)
        .background(MCRITheme.background.ignoresSafeArea())
        .onAppear { nameDraft = auth.session.displayName }
        .alert("Sign out?", isPresented: $showSignOutPrompt) {
            Button("Sign out", role: .destructive) { auth.signOut() }
            Button("Stay signed in", role: .cancel) {}
        } message: {
            Text("You will need your email and password to sign back in.")
        }
        .alert("Delete this account?", isPresented: $showDeletePrompt) {
            Button("Delete permanently", role: .destructive) { deleteAccount() }
            Button("Keep my account", role: .cancel) {}
        } message: {
            Text("Your profile, applications, saved roles and messages are removed and cannot be "
                 + "restored. Roles you posted stay with your company; ask them to remove the record "
                 + "if you leave the organisation.")
        }
    }

    private var identityCard: some View {
        MCRIScreenHero {
            HStack(spacing: MCRITheme.Spacing.s4) {
                MCRILogoTile(initials: auth.session.initials, size: 58,
                             imageURL: mcriAvatarURL(auth.session.avatarPath),
                             isCircle: auth.session.role != .employer)

                VStack(alignment: .leading, spacing: 3) {
                    Text(auth.session.displayName)
                        .font(.mcriTitle)
                        .foregroundStyle(MCRITheme.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(auth.session.email ?? "No email on file")
                        .font(.mcriFootnote)
                        .foregroundStyle(MCRITheme.textSecondary)
                    MCRIStatusBadge(auth.session.role.title, symbol: auth.session.role.glyph,
                                    tone: .information)
                        .padding(.top, 2)
                }
                Spacer(minLength: 0)
            }

            Text("The workspace you land in is set by your account on the server, so it cannot be "
                 + "changed from this device. \(auth.session.role.blurb).")
                .font(.mcriCaption2)
                .foregroundStyle(MCRITheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var nameCard: some View {
        MCRICard {
            VStack(alignment: .leading, spacing: MCRITheme.Spacing.s3) {
                MCRISectionHeader(title: "Display name",
                                  subtitle: auth.session.role == .employer
                                      ? "The talent team contact employers and students see"
                                      : "Shown on every application and caseload row")

                MCRIField(label: "Full name", placeholder: "As it should appear",
                          text: $nameDraft, autocapitalization: .words)

                MCRIButton(title: "Save name", symbol: "checkmark",
                           fullWidth: false,
                           isDisabled: nameDraft.trimmingCharacters(in: .whitespaces).count < 2
                                        || nameDraft == auth.session.displayName
                                        || auth.isBusy) {
                    Task { await store.updateAccountName(nameDraft) }
                }
            }
        }
    }

    private var securityCard: some View {
        MCRICard {
            VStack(alignment: .leading, spacing: MCRITheme.Spacing.s3) {
                if let notice = auth.infoMessage {
                    HStack(alignment: .top, spacing: MCRITheme.Spacing.s3) {
                        Image(systemName: "envelope.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(MCRITheme.secondaryAction)
                        Text(notice)
                            .font(.mcriFootnote)
                            .foregroundStyle(MCRITheme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer(minLength: 0)
                    }
                }

                if let error = auth.authError {
                    HStack(alignment: .top, spacing: MCRITheme.Spacing.s3) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(MCRITheme.blocked)
                        Text(error)
                            .font(.mcriFootnote)
                            .foregroundStyle(MCRITheme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer(minLength: 0)
                    }
                }

                MCRISecondaryButton(title: "Email me a password reset link",
                                    symbol: "key.fill",
                                    isDestructive: false,
                                    action: sendReset)

                Text("Reset links expire and can only be opened by this app. If you did not ask for "
                     + "one, no password was changed.")
                    .font(.mcriCaption2)
                    .foregroundStyle(MCRITheme.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var privacyCard: some View {
        MCRICard {
            VStack(alignment: .leading, spacing: MCRITheme.Spacing.s3) {
                MCRISectionHeader(title: "Who can read what",
                                  subtitle: "Enforced by Row Level Security, not by this app")

                bullet(store.session.role == .student
                       ? "Employers at verified companies see your profile, skills, projects and CV "
                         + "only for roles you apply to."
                       : "Your company record is visible to students once a manager verifies it.")
                bullet("Your programme office sees your full profile, applications and messages.")
                bullet("Your password is never stored in this app — the session token lives in the "
                       + "iPhone Keychain.")
                bullet("Analytics and support contact details are not collected.")
            }
        }
    }

    private var signOutCard: some View {
        MCRICard {
            VStack(alignment: .leading, spacing: MCRITheme.Spacing.s3) {
                Text("Signing out clears this device’s session. Your account and data stay on the server.")
                    .font(.mcriFootnote)
                    .foregroundStyle(MCRITheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                MCRISecondaryButton(title: "Sign out",
                                    symbol: "rectangle.portrait.and.arrow.right",
                                    isDestructive: true) {
                    showSignOutPrompt = true
                }
                .disabled(auth.isBusy)
            }
        }
    }

    private var deletionCard: some View {
        MCRICard(edge: .red) {
            VStack(alignment: .leading, spacing: MCRITheme.Spacing.s3) {
                MCRISectionHeader(title: "Delete account",
                                  subtitle: "Removes your records from the programme")
                Text("This deletes your profile, the roles or applications you own as a person, "
                     + "and every message you have sent. It cannot be undone.")
                    .font(.mcriFootnote)
                    .foregroundStyle(MCRITheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                MCRISecondaryButton(title: isDeleting ? "Deleting…" : "Delete my account",
                                    symbol: "trash",
                                    isDestructive: true) {
                    guard !isDeleting else { return }
                    showDeletePrompt = true
                }
                .disabled(isDeleting || auth.isBusy)
            }
        }
    }

    private func bullet(_ text: String) -> some View {
        HStack(alignment: .top, spacing: MCRITheme.Spacing.s2) {
            Image(systemName: "checkmark")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(MCRITheme.secondaryAction)
                .padding(.top, 3)
            Text(text)
                .font(.mcriFootnote)
                .foregroundStyle(MCRITheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
    }

    private func sendReset() {
        guard let email = auth.session.email, !auth.isBusy else {
            auth.infoMessage = "There is no email address on this account to reset."
            return
        }
        Task { await auth.sendPasswordReset(email: email) }
    }

    private func deleteAccount() {
        isDeleting = true
        Task {
            await auth.deleteAccount()
            isDeleting = false
        }
    }
}

private struct AccountViewPreview1: PreviewProvider {
    static var previews: some View {
    MCRIPreviewScreen(signedInAs: .student) { AccountView() }
}
}
