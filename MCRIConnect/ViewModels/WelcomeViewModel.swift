import Foundation
import Combine

/// Sign-in, create-account and password reset. The role a person asks for is only a request:
/// the workspace they land in comes back from `profiles.role`, never from this form.
@MainActor
final class WelcomeViewModel: ObservableObject {

    enum Form: String, Identifiable {
        case signIn
        case signUp
        case reset

        var id: String { rawValue }

        var title: String {
            switch self {
            case .signIn: return "Welcome back"
            case .signUp: return "Create your account"
            case .reset: return "Reset your password"
            }
        }

        var subtitle: String {
            switch self {
            case .signIn:
                return "Log in with the address you registered with your institution."
            case .signUp:
                return "Students and companies each get their own workspace."
            case .reset:
                return "We email a link to the address on your account. It expires after an hour."
            }
        }

        var actionTitle: String {
            switch self {
            case .signIn: return "Log in"
            case .signUp: return "Create account"
            case .reset: return "Send reset link"
            }
        }
    }

    @Published var openForm: Form?
    @Published var email = ""
    @Published var password = ""
    @Published var fullName = ""
    @Published var companyName = ""
    @Published var role: UserRole = .student
    @Published var errorText: String?

    private let auth: AuthService
    private var subscriptions = Set<AnyCancellable>()

    convenience init() {
        self.init(auth: AuthService.shared)
    }

    init(auth: AuthService) {
        self.auth = auth

        // Refresh the form when authentication state changes.
        auth.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &subscriptions)
    }

    var isBusy: Bool { auth.isBusy }

    var noticeText: String? { auth.infoMessage }

    /// Employers hire as a company, so the form will not submit without one.
    var needsCompanyName: Bool { openForm == .signUp && role == .employer }

    var canSubmit: Bool {
        let address = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !isBusy, address.isPlausibleEmail else { return false }

        switch openForm {
        case .signIn:
            return !password.isEmpty
        case .reset:
            return true
        case .signUp:
            let name = fullName.trimmingCharacters(in: .whitespacesAndNewlines)
            guard password.count >= 8, name.count >= 2 else { return false }
            if role == .employer {
                return companyName.trimmingCharacters(in: .whitespacesAndNewlines).count >= 2
            }
            return true
        case nil:
            return false
        }
    }

    // MARK: - Open Form

    func begin(_ form: Form) {
        errorText = nil
        auth.authError = nil
        auth.infoMessage = nil
        email = ""
        password = ""
        fullName = ""
        companyName = ""
        role = .student
        openForm = form
    }

    // MARK: - Submit Form

    func submit() async {
        guard let form = openForm, canSubmit else { return }
        errorText = nil
        let address = email.trimmingCharacters(in: .whitespacesAndNewlines)

        switch form {
        case .signIn:
            await auth.signIn(email: address, password: password)

        case .signUp:
            await auth.createAccount(email: address,
                                     password: password,
                                     role: role,
                                     fullName: fullName.trimmed,
                                     companyName: companyName.trimmed)

        case .reset:
            await auth.sendPasswordReset(email: address)
        }

        errorText = auth.authError

        // A reset request always reports the same line, so the form keeps it visible and
        // leaves the sheet open; a completed sign-in closes it.
        if auth.isSignedIn && errorText == nil {
            password = ""
            openForm = nil
        }
    }

    // MARK: - Close Form

    func close() {
        openForm = nil
        errorText = nil
        password = ""
    }
}

private extension String {
    var trimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }
}
