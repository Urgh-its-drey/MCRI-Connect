import Foundation
import Combine

@MainActor
final class WelcomeViewModel: ObservableObject {

    enum Form: String, Identifiable {
        case signIn
        case signUp

        var id: String { rawValue }
    }

    @Published var openForm: Form?
    @Published var email = ""
    @Published var password = ""
    @Published var fullName = ""
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

    var isBusy: Bool {
        auth.isBusy
    }

    var canSubmit: Bool {
        let trimmedEmail = email.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        let trimmedName = fullName.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard !isBusy,
              trimmedEmail.contains("@"),
              trimmedEmail.contains(".") else {
            return false
        }

        switch openForm {
        case .signIn:
            return !password.isEmpty

        case .signUp:
            return password.count >= 6 && trimmedName.count >= 2

        case nil:
            return false
        }
    }

    // MARK: - Open Form

    func begin(_ form: Form) {
        errorText = nil
        auth.authError = nil
        email = ""
        password = ""
        fullName = ""
        role = .student
        openForm = form
    }

    // MARK: - Submit Form

    func submit() async {
        guard let form = openForm, canSubmit else { return }

        errorText = nil

        let trimmedEmail = email.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        switch form {
        case .signIn:
            await auth.signIn(
                email: trimmedEmail,
                password: password
            )

        case .signUp:
            await auth.createAccount(
                email: trimmedEmail,
                password: password,
                role: role,
                fullName: fullName.trimmingCharacters(
                    in: .whitespacesAndNewlines
                )
            )
        }

        errorText = auth.authError

        // Keep confirmation messages and errors visible.
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
