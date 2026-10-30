import SwiftUI

/// The last step of a password reset. The emailed link hands the app a short-lived recovery
/// session that can do nothing else, so this sheet stands between that session and every
/// workspace until the person has replaced the password — or closes it, which signs the
/// recovery session out.
struct NewPasswordSheet: View {
    @EnvironmentObject private var auth: AuthService

    @State private var password = ""
    @State private var confirmation = ""

    private var isMatch: Bool { !password.isEmpty && password == confirmation }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: MCRITheme.Spacing.s5) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Choose a new password")
                        .font(.mcriTitle)
                        .foregroundStyle(MCRITheme.textPrimary)
                    Text(auth.session.email.map { "Resetting the password for \($0)." }
                         ?? "This link could not be opened, so no account is being reset.")
                        .font(.mcriFootnote)
                        .foregroundStyle(MCRITheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.top, MCRITheme.Spacing.s6)

                VStack(alignment: .leading, spacing: MCRITheme.Spacing.s4) {
                    MCRIField(label: "New password", placeholder: "At least 8 characters",
                              text: $password, isSecure: true)
                    MCRIField(label: "Confirm password", placeholder: "Type it again",
                              text: $confirmation, isSecure: true,
                              errorMessage: showMismatch ? "The two passwords do not match." : nil)

                    if let error = auth.authError {
                        HStack(alignment: .top, spacing: MCRITheme.Spacing.s2) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.caption)
                                .foregroundStyle(MCRITheme.blocked)
                            Text(error).font(.mcriCaption).foregroundStyle(MCRITheme.textSecondary)
                        }
                    }

                    if auth.isSignedIn {
                        MCRIButton(title: "Save new password", symbol: "checkmark",
                                   isDisabled: !isMatch || auth.isBusy,
                                   isLoading: auth.isBusy) {
                            Task { await auth.updatePassword(password) }
                        }
                    }

                    MCRISecondaryButton(title: auth.isSignedIn ? "Cancel this reset" : "Close",
                                        symbol: "xmark",
                                        isDestructive: auth.isSignedIn) {
                        auth.cancelPasswordReset()
                    }

                    Text("Only this app can open the link, and the link works once. If you did not "
                         + "ask for a reset, nothing has been changed.")
                        .font(.mcriCaption2)
                        .foregroundStyle(MCRITheme.textTertiary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.horizontal, MCRITheme.Spacing.screenMargin)
            .padding(.bottom, MCRITheme.Spacing.s8)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(MCRITheme.background)
    }

    private var showMismatch: Bool {
        !confirmation.isEmpty && !isMatch
    }
}

private struct NewPasswordSheetPreview1: PreviewProvider {
    static var previews: some View {
        MCRIPreviewScreen(inNavigationStack: false) { NewPasswordSheet() }
    }
}
