import AuthenticationServices
import Foundation
import Security

final class LocalAuthStore {
    enum AuthError: Error, Equatable {
        case invalidUsername
        case invalidPassword
        case accountExists
        case accountMissing
        case wrongPassword
        case emailConfirmationRequired
        case emailSignupsDisabled
        case generatedEmailRejected
        case invalidAppleCredential
        case missingConfiguration
        case networkFailure
        case keychainFailure
        case server(String)

        var message: String {
            switch self {
            case .invalidUsername:
                "Use 3-24 letters, numbers, dots, or underscores."
            case .invalidPassword:
                "Password must be at least 6 characters."
            case .accountExists:
                "That username already exists."
            case .accountMissing:
                "No account found for that username."
            case .wrongPassword:
                "Username or password is incorrect."
            case .emailConfirmationRequired:
                "Create the account again to finish setup."
            case .emailSignupsDisabled:
                "Turn Email signups on in Supabase Auth."
            case .generatedEmailRejected:
                "Supabase rejected this username. Try another one."
            case .invalidAppleCredential:
                "Apple did not return a valid login."
            case .missingConfiguration:
                "Supabase is not configured for this build."
            case .networkFailure:
                "Could not reach Supabase. Check your connection."
            case .keychainFailure:
                "Could not save login. Please try again."
            case .server(let message):
                message
            }
        }
    }

    static let shared = LocalAuthStore()

    private let service = "com.lunera.local-auth"
    private let sessionAccount = "supabase-session"
    private let signedInUsernameKey = "LUNERALocalSignedInUsername"
    private let urlSession: URLSession

    private lazy var configuration: LuneraSupabaseConfiguration? = {
        LuneraSupabaseConfiguration.fromBundle()
    }()

    private init(urlSession: URLSession = .shared) {
        self.urlSession = urlSession
    }

    var isSignedIn: Bool {
        guard let session = currentSession else {
            return false
        }

        guard !session.accessToken.isEmpty, !session.refreshToken.isEmpty else {
            signOut()
            return false
        }

        return true
    }

    var currentSession: SupabaseSession? {
        guard let data = sessionData() else {
            return nil
        }

        return try? JSONDecoder.luneraSupabase.decode(SupabaseSession.self, from: data)
    }

    @discardableResult
    func restoreSession() async -> Bool {
        guard let session = currentSession else {
            return false
        }

        guard !session.accessToken.isEmpty, !session.refreshToken.isEmpty else {
            signOut()
            return false
        }

        guard session.shouldRefresh else {
            return true
        }

        switch await refreshSession(refreshToken: session.refreshToken, username: session.username) {
        case .success:
            return true
        case .failure:
            signOut()
            return false
        }
    }

    func validAccessToken() async -> String? {
        guard await restoreSession(), let session = currentSession else {
            return nil
        }

        return session.accessToken
    }

    @discardableResult
    func createAccount(username: String, password: String) async -> Result<Void, AuthError> {
        let normalizedUsername = UsernameAuthMapper.normalize(username)
        guard UsernameAuthMapper.isValidUsername(normalizedUsername) else {
            return .failure(.invalidUsername)
        }
        guard UsernameAuthMapper.isValidPassword(password) else {
            return .failure(.invalidPassword)
        }

        let body: [String: Any] = [
            "username": normalizedUsername,
            "password": password
        ]

        do {
            let response: SupabaseAuthResponse = try await functionRequest(
                name: "username-signup",
                method: "POST",
                body: body,
                accessToken: nil
            )

            if let session = response.session(username: normalizedUsername) {
                return saveSession(session)
            }

            return .failure(.emailConfirmationRequired)
        } catch let error as AuthError {
            return .failure(error)
        } catch {
            return .failure(.networkFailure)
        }
    }

    @discardableResult
    func signIn(username: String, password: String) async -> Result<Void, AuthError> {
        let normalizedUsername = UsernameAuthMapper.normalize(username)
        guard UsernameAuthMapper.isValidUsername(normalizedUsername) else {
            return .failure(.invalidUsername)
        }
        guard UsernameAuthMapper.isValidPassword(password) else {
            return .failure(.invalidPassword)
        }

        let body: [String: Any] = [
            "email": UsernameAuthMapper.authEmail(for: normalizedUsername),
            "password": password
        ]

        do {
            let response: SupabaseAuthResponse = try await authRequest(
                path: "token",
                method: "POST",
                queryItems: [URLQueryItem(name: "grant_type", value: "password")],
                body: body,
                accessToken: nil
            )

            guard let session = response.session(username: normalizedUsername) else {
                return .failure(.wrongPassword)
            }

            return saveSession(session)
        } catch let error as AuthError {
            return .failure(error)
        } catch {
            return .failure(.networkFailure)
        }
    }

    @discardableResult
    func signInWithApple(authorization: ASAuthorization) -> Result<Void, AuthError> {
        guard (authorization.credential as? ASAuthorizationAppleIDCredential) != nil else {
            return .failure(.invalidAppleCredential)
        }

        return .failure(.server("Apple login still needs Supabase Apple provider setup."))
    }

    func signOut() {
        UserDefaults.standard.removeObject(forKey: signedInUsernameKey)
        SecItemDelete(keychainLookupQuery(account: sessionAccount) as CFDictionary)
    }

    private func refreshSession(refreshToken: String, username: String) async -> Result<Void, AuthError> {
        let body: [String: Any] = [
            "refresh_token": refreshToken
        ]

        do {
            let response: SupabaseAuthResponse = try await authRequest(
                path: "token",
                method: "POST",
                queryItems: [URLQueryItem(name: "grant_type", value: "refresh_token")],
                body: body,
                accessToken: nil
            )

            guard let session = response.session(username: username) else {
                return .failure(.wrongPassword)
            }

            return saveSession(session)
        } catch let error as AuthError {
            return .failure(error)
        } catch {
            return .failure(.networkFailure)
        }
    }

    private func sessionData() -> Data? {
        var query = keychainLookupQuery(account: sessionAccount)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess else {
            return nil
        }

        return item as? Data
    }

    private func saveSession(_ session: SupabaseSession) -> Result<Void, AuthError> {
        do {
            let data = try JSONEncoder.luneraSupabase.encode(session)
            let status = saveOrUpdateData(data, for: sessionAccount)
            guard status == errSecSuccess else {
                return .failure(.keychainFailure)
            }

            UserDefaults.standard.set(session.username, forKey: signedInUsernameKey)
            return .success(())
        } catch {
            return .failure(.keychainFailure)
        }
    }

    private func saveOrUpdateData(_ data: Data, for account: String) -> OSStatus {
        let addStatus = SecItemAdd(keychainQuery(account: account, data: data) as CFDictionary, nil)
        guard addStatus == errSecDuplicateItem else {
            return addStatus
        }

        let attributes = [kSecValueData as String: data]
        return SecItemUpdate(keychainLookupQuery(account: account) as CFDictionary, attributes as CFDictionary)
    }

    private func keychainQuery(account: String, data: Data) -> [String: Any] {
        var query = keychainLookupQuery(account: account)
        query[kSecValueData as String] = data
        query[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        return query
    }

    private func keychainLookupQuery(account: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
    }

    private func authRequest<Response: Decodable>(
        path: String,
        method: String,
        queryItems: [URLQueryItem] = [],
        body: [String: Any],
        accessToken: String?
    ) async throws -> Response {
        guard let configuration else {
            throw AuthError.missingConfiguration
        }

        var components = URLComponents(url: configuration.url.appending(path: "auth/v1/\(path)"), resolvingAgainstBaseURL: false)
        components?.queryItems = queryItems.isEmpty ? nil : queryItems
        guard let url = components?.url else {
            throw AuthError.missingConfiguration
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue(configuration.publishableKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(accessToken ?? configuration.publishableKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await urlSession.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthError.networkFailure
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw SupabaseAuthErrorMapper.map(data: data, statusCode: httpResponse.statusCode)
        }

        return try JSONDecoder.luneraSupabase.decode(Response.self, from: data)
    }

    private func functionRequest<Response: Decodable>(
        name: String,
        method: String,
        body: [String: Any],
        accessToken: String?
    ) async throws -> Response {
        guard let configuration else {
            throw AuthError.missingConfiguration
        }

        let url = configuration.url.appending(path: "functions/v1/\(name)")
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue(configuration.publishableKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(accessToken ?? configuration.publishableKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await urlSession.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthError.networkFailure
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw SupabaseAuthErrorMapper.map(data: data, statusCode: httpResponse.statusCode)
        }

        return try JSONDecoder.luneraSupabase.decode(Response.self, from: data)
    }
}

struct SupabaseSession: Codable, Equatable {
    let accessToken: String
    let refreshToken: String
    let expiresAt: Date?
    let userId: String
    let username: String

    var shouldRefresh: Bool {
        guard let expiresAt else {
            return false
        }

        return expiresAt <= Date().addingTimeInterval(60)
    }
}

struct SupabaseAuthResponse: Decodable {
    let accessToken: String?
    let refreshToken: String?
    let expiresIn: Int?
    let expiresAt: Int?
    let user: SupabaseUser?

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresIn = "expires_in"
        case expiresAt = "expires_at"
        case user
    }

    func session(username: String) -> SupabaseSession? {
        guard let accessToken,
              let refreshToken,
              let userId = user?.id else {
            return nil
        }

        let expiryDate: Date?
        if let expiresAt {
            expiryDate = Date(timeIntervalSince1970: TimeInterval(expiresAt))
        } else if let expiresIn {
            expiryDate = Date().addingTimeInterval(TimeInterval(expiresIn))
        } else {
            expiryDate = nil
        }

        return SupabaseSession(
            accessToken: accessToken,
            refreshToken: refreshToken,
            expiresAt: expiryDate,
            userId: userId,
            username: username
        )
    }
}

struct SupabaseUser: Decodable {
    let id: String
}

enum UsernameAuthMapper {
    static let usernameEmailDomain = "users.lunera.app"
    private static let allowedUsernameCharacters = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "._"))

    static func normalize(_ username: String) -> String {
        username.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    static func isValidUsername(_ username: String) -> Bool {
        guard (3...24).contains(username.count) else {
            return false
        }

        return username.unicodeScalars.allSatisfy { allowedUsernameCharacters.contains($0) }
    }

    static func isValidPassword(_ password: String) -> Bool {
        password.count >= 6
    }

    static func authEmail(for username: String) -> String {
        let safeLocalPart = username
            .replacingOccurrences(of: ".", with: "-dot-")
            .replacingOccurrences(of: "_", with: "-under-")

        return "\(safeLocalPart)@\(usernameEmailDomain)"
    }
}

enum SupabaseAuthErrorMapper {
    static func map(data: Data, statusCode: Int) -> LocalAuthStore.AuthError {
        let decoder = JSONDecoder()
        let errorResponse = try? decoder.decode(SupabaseErrorResponse.self, from: data)
        let rawMessage = errorResponse?.message
            ?? errorResponse?.errorDescription
            ?? errorResponse?.error
            ?? "Supabase returned an error."
        let normalized = "\(errorResponse?.code ?? "") \(rawMessage)".lowercased()

        if normalized.contains("email_provider_disabled")
            || normalized.contains("email signups are disabled") {
            return .emailSignupsDisabled
        }

        if normalized.contains("email_address_invalid")
            || (normalized.contains("email address") && normalized.contains("invalid")) {
            return .generatedEmailRejected
        }

        if normalized.contains("invalid_username") {
            return .invalidUsername
        }

        if normalized.contains("account_exists")
            || normalized.contains("already")
            || normalized.contains("registered") {
            return .accountExists
        }

        if normalized.contains("email not confirmed")
            || normalized.contains("email_not_confirmed")
            || normalized.contains("over_email_send_rate_limit")
            || normalized.contains("email rate limit")
            || normalized.contains("email address not authorized") {
            return .emailConfirmationRequired
        }

        if normalized.contains("invalid login") || normalized.contains("invalid credentials") {
            return .wrongPassword
        }

        if normalized.contains("password") && normalized.contains("characters") {
            return .invalidPassword
        }

        if statusCode == 400 {
            return .server(rawMessage)
        }

        return .server(rawMessage)
    }
}

private struct SupabaseErrorResponse: Decodable {
    let code: String?
    let message: String?
    let errorDescription: String?
    let error: String?

    enum CodingKeys: String, CodingKey {
        case errorCode = "error_code"
        case code
        case message = "msg"
        case messageText = "message"
        case errorDescription = "error_description"
        case error
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let errorCode = try? container.decodeIfPresent(String.self, forKey: .errorCode)
        let textCode = try? container.decodeIfPresent(String.self, forKey: .code)
        let numericCode = try? container.decodeIfPresent(Int.self, forKey: .code)
        code = errorCode ?? textCode ?? numericCode.map(String.init)
        message = try container.decodeIfPresent(String.self, forKey: .message)
            ?? container.decodeIfPresent(String.self, forKey: .messageText)
            ?? container.decodeIfPresent(String.self, forKey: .error)
        errorDescription = try container.decodeIfPresent(String.self, forKey: .errorDescription)
        error = try container.decodeIfPresent(String.self, forKey: .error)
    }
}
