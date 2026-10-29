import Foundation
import Combine
import Supabase

@MainActor
final class AuthService: ObservableObject {
    static let shared = AuthService()

    @Published private(set) var session: Session = .signedOut
    @Published private(set) var isBusy = false
    @Published var needsOnboarding = false
    @Published var authError: String?

    private var listener: Task<Void, Never>?

    init() {
        // Remove the previous demo login.
        UserDefaults.standard.removeObject(forKey: "mcri.session")

        // Listen for restored sessions, sign-in, and sign-out.
        listener = Task { [weak self] in
            for await (_, remoteSession) in supabase.auth.authStateChanges {
                guard let self else { return }

                if let remoteSession {
                    self.apply(remoteSession.user)
                } else {
                    self.session = .signedOut
                    self.needsOnboarding = false
                }
            }
        }
    }

    deinit {
        listener?.cancel()
    }

    var isSignedIn: Bool {
        session.isAuthenticated
    }

    // MARK: - Sign In

    func signIn(email: String, password: String) async {
        guard !isBusy,
              validate(email: email, password: password) else {
            return
        }

        isBusy = true
        defer { isBusy = false }

        do {
            let remoteSession = try await supabase.auth.signIn(
                email: email.trimmingCharacters(
                    in: .whitespacesAndNewlines
                ),
                password: password
            )

            apply(remoteSession.user)
        } catch {
            authError = error.localizedDescription
        }
    }

    // MARK: - Create Account

    func createAccount(
        email: String,
        password: String,
        role: UserRole,
        fullName: String = ""
    ) async {
        guard !isBusy,
              validate(email: email, password: password) else {
            return
        }

        guard role != .programManager else {
            authError = """
            Program manager accounts must be invited \
            by an administrator.
            """
            return
        }

        isBusy = true
        defer { isBusy = false }

        do {
            let result = try await supabase.auth.signUp(
                email: email.trimmingCharacters(
                    in: .whitespacesAndNewlines
                ),
                password: password,
                data: [
                    "full_name": .string(fullName),
                    "requested_role": .string(role.rawValue)
                ]
            )

            if let remoteSession = result.session {
                needsOnboarding = role == .student
                apply(remoteSession.user)
            } else {
                authError = """
                Check your email to confirm your account, \
                then sign in.
                """
            }
        } catch {
            authError = error.localizedDescription
        }
    }

    // MARK: - Sign Out

    func signOut() {
        guard !isBusy else { return }

        isBusy = true

        Task {
            defer { isBusy = false }

            do {
                try await supabase.auth.signOut()

                session = .signedOut
                needsOnboarding = false
                authError = nil
            } catch {
                authError = error.localizedDescription
            }
        }
    }

    // MARK: - Profile

    func updateDisplayName(_ name: String) {
        guard isSignedIn else { return }

        Task {
            do {
                let user = try await supabase.auth.update(
                    user: UserAttributes(
                        data: [
                            "full_name": .string(name)
                        ]
                    )
                )

                apply(user)
            } catch {
                authError = error.localizedDescription
            }
        }
    }

    func completeOnboarding() {
        needsOnboarding = false
    }

    // MARK: - Existing Demo Actions

    // These methods keep existing views compatible,
    // but no longer allow bypassing authentication.

    func continueAs(_ role: UserRole) {
        authError = "Please sign in with your account."
    }

    func begin(role: UserRole, as displayName: String) {
        authError = "Please sign in with your account."
    }

    func switchRole(_ role: UserRole) {
        authError = """
        Your account role is managed by your administrator.
        """
    }

    // MARK: - Update App Session

    private func apply(_ user: User) {
        // Privileged roles must be assigned by the server.
        let roleValue = user.appMetadata["role"]?.stringValue
            ?? "student"

        let role = UserRole(rawValue: roleValue) ?? .student

        let fullName = user.userMetadata["full_name"]?.stringValue
            ?? ""

        let displayName = fullName.isEmpty
            ? (user.email ?? "Member")
            : fullName

        let initials = String(
            displayName
                .split(separator: " ")
                .prefix(2)
                .compactMap { $0.first }
        )
        .uppercased()

        session = Session(
            role: role,
            displayName: displayName,
            initials: initials,
            isAuthenticated: true
        )
    }

    // MARK: - Validation

    private func validate(
        email: String,
        password: String
    ) -> Bool {
        authError = nil

        let trimmedEmail = email.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard trimmedEmail.contains("@"),
              trimmedEmail.contains("."),
              !password.isEmpty else {
            authError = "Enter your email address and password."
            return false
        }

        return true
    }
}
