import Foundation

final class ProfileRepository {
    private let restClient: SupabaseRESTClient
    private let authRepository: AuthRepository

    init(restClient: SupabaseRESTClient = SupabaseRESTClient(), authRepository: AuthRepository = .shared) {
        self.restClient = restClient
        self.authRepository = authRepository
    }

    func fetchCurrentProfile() async throws -> Profile? {
        guard let userId = authRepository.currentSession?.userId else {
            throw RepositoryError.notAuthenticated
        }

        let profiles: [Profile] = try await restClient.get(
            table: "profiles",
            queryItems: [
                URLQueryItem(name: "select", value: "*"),
                URLQueryItem(name: "id", value: "eq.\(userId)"),
                URLQueryItem(name: "limit", value: "1")
            ]
        )

        return profiles.first
    }

    func updateCurrentProfile(displayName: String?, avatarURL: URL?, homeCity: String) async throws -> Profile {
        guard let userId = authRepository.currentSession?.userId else {
            throw RepositoryError.notAuthenticated
        }

        let payload = ProfileUpdatePayload(
            displayName: displayName,
            avatarURL: avatarURL,
            homeCity: homeCity
        )

        let profiles: [Profile] = try await restClient.patch(
            table: "profiles",
            queryItems: [
                URLQueryItem(name: "id", value: "eq.\(userId)")
            ],
            body: payload
        )

        guard let profile = profiles.first else {
            throw RepositoryError.server(statusCode: 204, message: "Profile update returned no row.")
        }

        return profile
    }
}

private struct ProfileUpdatePayload: Encodable {
    let displayName: String?
    let avatarURL: URL?
    let homeCity: String

    enum CodingKeys: String, CodingKey {
        case displayName = "display_name"
        case avatarURL = "avatar_url"
        case homeCity = "home_city"
    }
}
