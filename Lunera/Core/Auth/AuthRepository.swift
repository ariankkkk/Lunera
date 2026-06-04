import AuthenticationServices
import Foundation

final class AuthRepository {
    static let shared = AuthRepository(store: .shared)

    private let store: LocalAuthStore

    init(store: LocalAuthStore) {
        self.store = store
    }

    var isSignedIn: Bool {
        store.isSignedIn
    }

    var currentSession: SupabaseSession? {
        store.currentSession
    }

    @discardableResult
    func restoreSession() async -> Bool {
        await store.restoreSession()
    }

    func validAccessToken() async -> String? {
        await store.validAccessToken()
    }

    @discardableResult
    func createAccount(username: String, password: String) async -> Result<Void, LocalAuthStore.AuthError> {
        await store.createAccount(username: username, password: password)
    }

    @discardableResult
    func signIn(username: String, password: String) async -> Result<Void, LocalAuthStore.AuthError> {
        await store.signIn(username: username, password: password)
    }

    @discardableResult
    func signInWithApple(authorization: ASAuthorization) -> Result<Void, LocalAuthStore.AuthError> {
        store.signInWithApple(authorization: authorization)
    }

    func signOut() {
        store.signOut()
    }
}
