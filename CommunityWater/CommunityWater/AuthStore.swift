import Foundation
import Combine

struct AuthUser: Codable, Equatable {
    let id: String
    let email: String?
}

struct AuthResponse: Decodable {
    let access_token: String?
    let user: AuthUser?
}

enum AuthAction: String { case signIn, signUp }

protocol AuthenticationService: Sendable {
    func authenticate(action: AuthAction, email: String, password: String, name: String) async throws -> AuthResponse
}

struct SupabaseAuthentication: AuthenticationService {
    let configuration: BackendConfiguration

    func authenticate(action: AuthAction, email: String, password: String, name: String) async throws -> AuthResponse {
        guard let base = configuration.endpoint, configuration.isValid else { throw AuthenticationError.notConfigured }
        let path = action == .signIn ? "auth/v1/token" : "auth/v1/signup"
        var components = URLComponents(url: base.appendingPathComponent(path), resolvingAgainstBaseURL: false)!
        if action == .signIn { components.queryItems = [.init(name: "grant_type", value: "password")] }
        var request = URLRequest(url: components.url!)
        request.httpMethod = "POST"
        request.timeoutInterval = 25
        request.setValue(configuration.key, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        var payload: [String: Any] = ["email": email, "password": password]
        if action == .signUp { payload["data"] = ["display_name": name] }
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw URLError(.badServerResponse) }
        guard (200..<300).contains(http.statusCode) else {
            // Keep server payloads and credentials out of UI errors and logs.
            if http.statusCode == 429 { throw AuthenticationError.rateLimited }
            throw action == .signIn ? AuthenticationError.signInFailed : AuthenticationError.signUpFailed
        }
        return try JSONDecoder().decode(AuthResponse.self, from: data)
    }
}

enum AuthenticationError: LocalizedError {
    case notConfigured, signInFailed, signUpFailed, rateLimited
    var errorDescription: String? {
        switch self {
        case .notConfigured: "Connect your community in Settings before using an account. You can also explore as a guest."
        case .signInFailed: "Could not sign in. Check your email and password, and confirm your email if you have just signed up."
        case .signUpFailed: "Could not create your account. Check the details or try signing in if you already have an account. Your community may also have sign-ups disabled."
        case .rateLimited: "Too many attempts. Please wait a few minutes before trying again."
        }
    }
}

@MainActor
final class AuthStore: ObservableObject {
    @Published private(set) var user: AuthUser?
    @Published private(set) var isGuest = false
    @Published private(set) var busy = false
    @Published private(set) var confirmationEmail: String?
    @Published var message: String?
    var canExplore: Bool { user != nil || isGuest }

    static func validEmail(_ value: String) -> Bool {
        let parts = value.split(separator: "@", omittingEmptySubsequences: false)
        return parts.count == 2 && !parts[0].isEmpty && parts[1].contains(".") &&
            !parts[1].hasPrefix(".") && !parts[1].hasSuffix(".") &&
            !value.contains(where: { $0.isWhitespace })
    }

    func exploreAsGuest() { user = nil; isGuest = true; clearFeedback() }
    func signOut() { user = nil; isGuest = false; clearFeedback() }
    func clearFeedback() { message = nil; confirmationEmail = nil }

    @discardableResult
    func submit(action: AuthAction, email: String, password: String, name: String = "", confirmation: String = "",
                configuration: BackendConfiguration?, service: (any AuthenticationService)? = nil) async -> Bool {
        guard !busy else { return false }
        clearFeedback()
        let email = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard Self.validEmail(email) else { message = "Enter a valid email address."; return false }
        guard !password.isEmpty else { message = "Enter your password."; return false }
        if action == .signUp {
            guard password.count >= 8 else { message = "Use a password with at least 8 characters."; return false }
            guard password == confirmation else { message = "Your passwords do not match."; return false }
        }
        guard let configuration, configuration.isValid else {
            message = AuthenticationError.notConfigured.localizedDescription; return false
        }
        busy = true
        defer { busy = false }
        do {
            let result = try await (service ?? SupabaseAuthentication(configuration: configuration))
                .authenticate(action: action, email: email, password: password, name: name.trimmingCharacters(in: .whitespacesAndNewlines))
            if let token = result.access_token, !token.isEmpty, let user = result.user {
                self.user = user; isGuest = false
            } else if action == .signUp {
                // Supabase can return the same confirmation response for an existing email.
                confirmationEmail = email
            } else { throw AuthenticationError.signInFailed }
            return true
        } catch {
            if let authError = error as? AuthenticationError { message = authError.localizedDescription }
            else { message = "Could not connect. Check your internet connection and try again." }
            return false
        }
    }
}
