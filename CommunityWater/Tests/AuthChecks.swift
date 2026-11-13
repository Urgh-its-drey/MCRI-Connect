import Foundation

struct TestAuthentication: AuthenticationService {
    var response: AuthResponse
    var fails = false
    func authenticate(action: AuthAction, email: String, password: String, name: String) async throws -> AuthResponse {
        if fails { throw AuthenticationError.signInFailed }
        return response
    }
}

@main
struct AuthChecks {
    @MainActor static func main() async {
        let auth = AuthStore()
        let config = BackendConfiguration(url: "https://test-community.supabase.co", key: "sb_publishable_test")
        let user = AuthUser(id: "test-user", email: "resident@example.com")
        let immediate = TestAuthentication(response: AuthResponse(access_token: "test-token", user: user))
        precondition(!auth.canExplore)
        auth.exploreAsGuest()
        precondition(auth.isGuest && auth.canExplore && auth.user == nil)
        auth.signOut()
        precondition(!auth.canExplore)
        precondition(AuthStore.validEmail("resident@example.com"))
        precondition(!AuthStore.validEmail("bad@@example.com"))
        precondition(!AuthStore.validEmail("resident@.com"))

        var success = await auth.submit(action: .signUp, email: "bad", password: "password1", confirmation: "password1", configuration: config, service: immediate)
        precondition(!success && auth.message != nil && auth.user == nil)
        success = await auth.submit(action: .signUp, email: user.email!, password: "short", confirmation: "short", configuration: config, service: immediate)
        precondition(!success)
        success = await auth.submit(action: .signUp, email: user.email!, password: "password1", confirmation: "different", configuration: config, service: immediate)
        precondition(!success)
        success = await auth.submit(action: .signIn, email: user.email!, password: "password1", configuration: nil, service: immediate)
        precondition(!success && !auth.canExplore)

        let confirmation = TestAuthentication(response: AuthResponse(access_token: nil, user: user))
        success = await auth.submit(action: .signUp, email: "  resident@example.com  ", password: "password1", confirmation: "password1", configuration: config, service: confirmation)
        precondition(success && auth.confirmationEmail == user.email && !auth.canExplore)
        success = await auth.submit(action: .signIn, email: user.email!, password: "password1", configuration: config, service: confirmation)
        precondition(!success && !auth.canExplore)

        let failed = TestAuthentication(response: immediate.response, fails: true)
        success = await auth.submit(action: .signIn, email: user.email!, password: "password1", configuration: config, service: failed)
        precondition(!success && auth.message != nil && !auth.busy)
        success = await auth.submit(action: .signIn, email: user.email!, password: "password1", configuration: config, service: immediate)
        precondition(success && auth.user == user && auth.canExplore && !auth.isGuest)
        auth.signOut()
        precondition(auth.user == nil && !auth.canExplore && auth.message == nil)
        success = await auth.submit(action: .signUp, email: user.email!, password: "password1", name: "Resident", confirmation: "password1", configuration: config, service: immediate)
        precondition(success && auth.user == user)
        print("PASS: guest access, sign-out, validation, missing configuration, confirmation flow, failed sign-in, successful sign-in and immediate sign-up")
    }
}
