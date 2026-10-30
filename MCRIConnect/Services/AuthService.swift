import Foundation
import Combine
import Supabase

/// Owns the signed-in identity. The workspace the app opens is decided by the `role` column
/// in Supabase — never by a value the device can edit, which is what previously dropped every
/// manager into the student tab set.
@MainActor
final class AuthService: ObservableObject {
    static let shared = AuthService()

    @Published private(set) var session: Session = .signedOut
    @Published private(set) var isBusy = false
    /// True between "the token is valid" and "the server told us this person's role". The
    /// workspace must not open before then, or a manager would briefly render student tabs.
    @Published private(set) var isResolvingProfile = false
    @Published var needsOnboarding = false
    @Published var authError: String?
    /// Lines that are not failures: a reset link has been sent, a confirmation email is
    /// on its way. Shown apart from `authError` so the form never cries wolf.
    @Published var infoMessage: String?
    /// True between the reset link opening and the new password being saved. The recovery
    /// session the link hands back is short-lived and cannot be used for anything else, so
    /// the app holds a "choose a new password" sheet over whatever workspace opened.
    @Published private(set) var isAwaitingNewPassword = false

    private let service: DataService
    private var listener: Task<Void, Never>?
    #if DEBUG
    /// Set by the preview seam. The SDK's auth stream is not cancellation-aware, so a
    /// suspended `for await` keeps delivering real events after the listener task is
    /// cancelled — and a signed-out event would wipe the seeded identity straight back to
    /// the welcome screen.
    private var isPreviewSeeded = false
    #endif

    convenience init() {
        self.init(service: SupabaseDataService())
    }

    init(service: DataService) {
        self.service = service

        // Any session left by an older build of this app is discarded: roles changed shape
        // and a stale record must never decide which workspace opens.
        UserDefaults.standard.removeObject(forKey: "mcri.session")

        listener = Task { [weak self] in
            guard let self else { return }
            for await (_, remoteSession) in supabase.auth.authStateChanges {
                #if DEBUG
                if self.isPreviewSeeded { continue }
                #endif
                if let remoteSession {
                    await self.resolve(from: remoteSession.user)
                } else {
                    self.session = .signedOut
                    self.needsOnboarding = false
                    self.isAwaitingNewPassword = false
                }
            }
        }

        // The SDK keeps the refresh token in the Keychain. Restoring it is what makes a
        // relaunch land straight in the right workspace instead of the welcome screen.
        Task { [weak self] in
            guard let self, !self.session.isAuthenticated else { return }
            if let remoteSession = try? await supabase.auth.session {
                await self.resolve(from: remoteSession.user)
            }
        }
    }

    deinit {
        listener?.cancel()
    }

    var isSignedIn: Bool { session.isAuthenticated }

    // MARK: - Sign in

    func signIn(email: String, password: String) async {
        let address = email.trimmedEmail
        guard !isBusy, validateSignIn(email: address, password: password) else { return }

        isBusy = true
        authError = nil
        infoMessage = nil
        defer { isBusy = false }

        do {
            let remote = try await supabase.auth.signIn(email: address, password: password)
            await resolve(from: remote.user)
        } catch {
            // One wording for a wrong address and a wrong password: the form must not
            // become a way to learn which emails have accounts.
            authError = "That email and password combination does not match an account."
        }
    }

    // MARK: - Create account

    /// Students and employers self-serve. A manager role is only granted when the email
    /// domain is on the server-side allowlist, so this call cannot mint a manager.
    func createAccount(email: String, password: String, role: UserRole,
                       fullName: String, companyName: String = "") async {
        let address = email.trimmedEmail
        let name = fullName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !isBusy, validateSignUp(email: address, password: password, fullName: name) else { return }
        guard role != .employer || companyName.trimmedEmail.count >= 2 else {
            authError = "Enter the company name you hire under."
            return
        }

        isBusy = true
        defer { isBusy = false }

        var metadata: [String: AnyJSON] = [
            "full_name": .string(name),
            "requested_role": .string(role.rawValue),
        ]
        if role == .employer {
            metadata["company_name"] = .string(companyName.trimmingCharacters(in: .whitespacesAndNewlines))
        }

        do {
            let result = try await supabase.auth.signUp(email: address, password: password,
                                                       data: metadata)
            if let remote = result.session {
                await resolve(from: remote.user)
                needsOnboarding = role.requiresOnboarding && session.role == .student
            } else {
                infoMessage = "We sent a confirmation link to \(address). Open it, then sign in."
            }
        } catch {
            authError = "We could not create that account. Check the address and try again."
        }
    }

    // MARK: - Password reset

    func sendPasswordReset(email: String) async {
        let address = email.trimmedEmail
        guard validateResetRequest(email: address) else { return }
        isBusy = true
        defer { isBusy = false }
        // One wording whether or not the address exists: the form must not confirm which
        // emails have accounts.
        do {
            try await supabase.auth.resetPasswordForEmail(address,
                                                          redirectTo: SupabaseConfiguration.resetRedirect)
            infoMessage = "If that address has an account, a reset link is on its way."
        } catch {
            infoMessage = "If that address has an account, a reset link is on its way."
        }
    }

    // MARK: - Reset link

    /// Handles the `mcri-connect://` callback Supabase opens when the emailed link is tapped.
    /// The link carries a one-use code, so the exchange has to happen on the device that asked
    /// for the reset — the code verifier never leaves it.
    func handleResetLink(_ url: URL) async {
        guard url.scheme?.lowercased() == SupabaseConfiguration.resetScheme else { return }
        isBusy = true
        defer { isBusy = false }

        do {
            let recovered = try await supabase.auth.session(from: url)
            isAwaitingNewPassword = true
            await resolve(from: recovered.user)
        } catch {
            // Same wording whatever GoTrue said: the detail is a token state, not something
            // the person can act on.
            authError = "That reset link has expired or was already used. Request a new one."
            isAwaitingNewPassword = true
        }
    }

    func updatePassword(_ password: String) async {
        guard validateNewPassword(password) else { return }
        isBusy = true
        defer { isBusy = false }
        do {
            _ = try await supabase.auth.update(user: UserAttributes(password: password))
            isAwaitingNewPassword = false
            authError = nil
            infoMessage = "Your password has been changed and you are signed in."
        } catch {
            authError = "We could not change the password. Request a fresh link and try again."
        }
    }

    /// Closing the sheet without saving discards the recovery session: it grants the account
    /// for an hour, and a device left holding it is a door left open.
    func cancelPasswordReset() {
        isAwaitingNewPassword = false
        authError = nil
        infoMessage = nil
        guard session.isAuthenticated else { return }
        Task {
            try? await supabase.auth.signOut()
            self.session = .signedOut
        }
    }

    // MARK: - Sign out

    func signOut() {
        guard !isBusy else { return }
        isBusy = true
        Task {
            defer { isBusy = false }
            try? await supabase.auth.signOut()
            session = .signedOut
            needsOnboarding = false
            isAwaitingNewPassword = false
            authError = nil
            infoMessage = nil
        }
    }

    // MARK: - Account

    func updateDisplayName(_ name: String) async {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard isSignedIn, trimmed.count >= 2 else { return }
        session.displayName = trimmed
        session.initials = NameParts.initials(trimmed)
        do {
            try await supabase.from("profiles")
                .update(["full_name": AnyJSON.string(trimmed)])
                .eq("id", value: session.id?.uuidString ?? "")
                .execute()
        } catch {
            authError = error.localizedDescription
        }
    }

    /// Called once the storage upload for a new photo has landed.
    func setAvatarPath(_ path: String) async {
        guard isSignedIn, let id = session.id else { return }
        session.avatarPath = path
        do {
            try await supabase.from("profiles")
                .update(["avatar_path": AnyJSON.string(path)])
                .eq("id", value: id.uuidString)
                .execute()
        } catch {
            authError = error.localizedDescription
        }
    }

    func completeOnboarding() {
        needsOnboarding = false
    }

    /// Apple 5.1.1(v): an account must be removable from inside the app.
    func deleteAccount() async {
        guard isSignedIn else { return }
        isBusy = true
        defer { isBusy = false }
        do {
            try await service.deleteAccount()
            try? await supabase.auth.signOut()
            session = .signedOut
            needsOnboarding = false
            isAwaitingNewPassword = false
            authError = nil
            infoMessage = "Your account and its records were deleted."
        } catch {
            authError = "We could not delete the account. Try again while online."
        }
    }

    /// Where a role is allowed to go. Views call this instead of trusting their own tab bar.
    func canOpen(_ role: UserRole) -> Bool {
        isSignedIn && session.role == role
    }

    // MARK: - Resolution

    /// Reads the server's verdict on who this is, then publishes a session for one workspace.
    private func resolve(from user: User) async {
        #if DEBUG
        if isPreviewSeeded { return }
        #endif
        guard session.id != user.id || !session.isAuthenticated else { return }
        isResolvingProfile = true
        defer { isResolvingProfile = false }

        // Nothing about the role is trusted from here — the placeholder carries the auth uid
        // only, and `apply(record)` replaces the role from the `profiles` row. RootView keeps
        // the splash up while `isResolvingProfile` is true, so no wrong workspace renders.
        session = Session(id: user.id, role: .student,
                          displayName: user.preferredDisplayName,
                          initials: NameParts.initials(user.preferredDisplayName),
                          email: user.email, companyID: nil, avatarPath: nil,
                          isAuthenticated: true)

        do {
            guard let record = try await service.profile(for: session) else {
                authError = DataError.schemaMissing.localizedDescription
                return
            }
            apply(record)
        } catch {
            authError = error.localizedDescription
        }
    }

    private func apply(_ record: ProfileRecord) {
        guard let id = session.id else { return }

        if record.status != "active" {
            authError = "This account is \(record.status). Contact your programme manager."
            Task { try? await supabase.auth.signOut(); self.session = .signedOut }
            return
        }

        let name = record.fullName.isEmpty ? (record.email ?? "Member") : record.fullName
        session = Session(id: id,
                          role: record.role,
                          displayName: name,
                          initials: NameParts.initials(name),
                          email: record.email,
                          companyID: record.companyID,
                          avatarPath: record.avatarPath,
                          isAuthenticated: true)

        // A student whose profile row is still the empty shell sign-up made has not onboarded.
        if record.role == .student {
            needsOnboarding = record.fullName.isEmpty || session.displayName.isEmpty
        } else {
            needsOnboarding = false
        }
    }

    // MARK: - Validation

    private func validateSignIn(email: String, password: String) -> Bool {
        authError = nil
        guard email.isPlausibleEmail, !password.isEmpty else {
            authError = "Enter your email address and password."
            return false
        }
        return true
    }

    private func validateSignUp(email: String, password: String, fullName: String) -> Bool {
        authError = nil
        guard email.isInstitutionFriendly, !email.isDisposableDomain else {
            authError = "Use the email address your institution or company issued to you."
            return false
        }
        guard fullName.count >= 2 else {
            authError = "Enter your full name as it should appear to employers."
            return false
        }
        return validateNewPassword(password)
    }

    /// The same bar for a chosen password and for a reset one — 8 characters is the App Store
    /// expectation, and spaces are what turns a paste-trailing-space into a locked account.
    private func validateNewPassword(_ password: String) -> Bool {
        authError = nil
        guard password.count >= 8 else {
            authError = "Use at least 8 characters for your password."
            return false
        }
        guard password.rangeOfCharacter(from: .whitespacesAndNewlines) == nil else {
            authError = "Passwords cannot contain spaces."
            return false
        }
        return true
    }

    private func validateResetRequest(email: String) -> Bool {
        authError = nil
        guard email.isPlausibleEmail else {
            authError = "Enter the email address on your account."
            return false
        }
        return true
    }

    #if DEBUG
    /// Previews and simulator screenshots have no Supabase account to read a role from, so
    /// they seed one that matches the bundled snapshot. Debug builds only — a Release binary
    /// can only reach a workspace through `resolve(from:)`, i.e. through the server's role.
    func seedForPreview(role: UserRole, id: UUID, displayName: String, companyID: UUID? = nil) {
        listener?.cancel()
        listener = nil
        isPreviewSeeded = true
        session = Session(id: id, role: role, displayName: displayName,
                          initials: NameParts.initials(displayName), email: "preview@mcri.ac.za",
                          companyID: companyID, avatarPath: nil, isAuthenticated: true)
        needsOnboarding = false
        authError = nil
        isResolvingProfile = false
    }
    #endif
}

private extension User {
    var preferredDisplayName: String {
        let stored = userMetadata["full_name"]?.stringValue ?? ""
        return stored.isEmpty ? (email ?? "Member") : stored
    }
}

extension String {
    var trimmedEmail: String { trimmingCharacters(in: .whitespacesAndNewlines) }

    var isPlausibleEmail: Bool {
        range(of: #"^[^@\s]+@[^@\s]+\.[A-Za-z]{2,}$"#, options: .regularExpression) != nil
    }

    /// Institution and company addresses only — free inboxes cannot be tied to a cohort.
    var isInstitutionFriendly: Bool { isPlausibleEmail }

    var isDisposableDomain: Bool {
        let disposable: Set<String> = ["mailinator.com", "tempmail.com", "10minutemail.com",
                                       "guerrillamail.com", "yopmail.com", "trashmail.com"]
        guard let domain = split(separator: "@").last else { return false }
        return disposable.contains(domain.lowercased())
    }
}
