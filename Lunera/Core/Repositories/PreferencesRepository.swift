import Foundation

final class PreferencesRepository {
    private let restClient: SupabaseRESTClient
    private let authRepository: AuthRepository

    init(restClient: SupabaseRESTClient = SupabaseRESTClient(), authRepository: AuthRepository = .shared) {
        self.restClient = restClient
        self.authRepository = authRepository
    }

    func fetchCurrentPreferences() async throws -> UserPreference? {
        guard let userId = authRepository.currentSession?.userId else {
            throw RepositoryError.notAuthenticated
        }

        let preferences: [UserPreference] = try await restClient.get(
            table: "user_preferences",
            queryItems: [
                URLQueryItem(name: "select", value: "*"),
                URLQueryItem(name: "user_id", value: "eq.\(userId)"),
                URLQueryItem(name: "limit", value: "1")
            ]
        )

        return preferences.first
    }

    func saveCurrentPreferences(_ input: UserPreferenceInput) async throws -> UserPreference {
        guard let userIdString = authRepository.currentSession?.userId,
              let userId = UUID(uuidString: userIdString) else {
            throw RepositoryError.notAuthenticated
        }

        let payload = UserPreferenceUpsertPayload(userId: userId, input: input)
        let preferences: [UserPreference] = try await restClient.post(
            table: "user_preferences",
            queryItems: [
                URLQueryItem(name: "on_conflict", value: "user_id")
            ],
            prefer: "resolution=merge-duplicates,return=representation",
            body: payload
        )

        guard let preference = preferences.first else {
            throw RepositoryError.server(statusCode: 204, message: "Preference save returned no row.")
        }

        return preference
    }

    func deleteCurrentPreferences() async throws {
        guard let userId = authRepository.currentSession?.userId else {
            throw RepositoryError.notAuthenticated
        }

        let _: EmptyResponse = try await restClient.delete(
            table: "user_preferences",
            queryItems: [
                URLQueryItem(name: "user_id", value: "eq.\(userId)")
            ]
        )
    }
}

struct UserPreferenceInput: Equatable, Sendable {
    var sizes: [String: JSONValue] = [:]
    var preferredColors: [String] = []
    var blockedColors: [String] = []
    var preferredBrands: [String] = []
    var blockedBrands: [String] = []
    var priceMin: Decimal?
    var priceMax: Decimal?
    var preferredStoreIds: [UUID] = []
    var styleTags: [String] = []
    var fitPreferences: [String] = []
}

private struct UserPreferenceUpsertPayload: Encodable {
    let userId: UUID
    let sizes: [String: JSONValue]
    let preferredColors: [String]
    let blockedColors: [String]
    let preferredBrands: [String]
    let blockedBrands: [String]
    let priceMin: Decimal?
    let priceMax: Decimal?
    let preferredStoreIds: [UUID]
    let styleTags: [String]
    let fitPreferences: [String]

    init(userId: UUID, input: UserPreferenceInput) {
        self.userId = userId
        sizes = input.sizes
        preferredColors = input.preferredColors
        blockedColors = input.blockedColors
        preferredBrands = input.preferredBrands
        blockedBrands = input.blockedBrands
        priceMin = input.priceMin
        priceMax = input.priceMax
        preferredStoreIds = input.preferredStoreIds
        styleTags = input.styleTags
        fitPreferences = input.fitPreferences
    }

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case sizes
        case preferredColors = "preferred_colors"
        case blockedColors = "blocked_colors"
        case preferredBrands = "preferred_brands"
        case blockedBrands = "blocked_brands"
        case priceMin = "price_min"
        case priceMax = "price_max"
        case preferredStoreIds = "preferred_store_ids"
        case styleTags = "style_tags"
        case fitPreferences = "fit_preferences"
    }
}
