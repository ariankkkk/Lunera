import Foundation

final class RecommendationRepository {
    private let restClient: SupabaseRESTClient
    private let authRepository: AuthRepository

    init(restClient: SupabaseRESTClient = SupabaseRESTClient(), authRepository: AuthRepository = .shared) {
        self.restClient = restClient
        self.authRepository = authRepository
    }

    func fetchRecommendations(eventId: UUID? = nil) async throws -> [OutfitRecommendation] {
        guard let userId = authRepository.currentSession?.userId else {
            throw RepositoryError.notAuthenticated
        }

        var queryItems = [
            URLQueryItem(name: "select", value: "*"),
            URLQueryItem(name: "user_id", value: "eq.\(userId)"),
            URLQueryItem(name: "order", value: "created_at.desc")
        ]

        if let eventId {
            queryItems.append(URLQueryItem(name: "event_id", value: "eq.\(eventId.uuidString)"))
        }

        return try await restClient.get(table: "outfit_recommendations", queryItems: queryItems)
    }

    func submitFeedback(_ input: RecommendationFeedbackInput) async throws -> RecommendationFeedback {
        guard let userIdString = authRepository.currentSession?.userId,
              let userId = UUID(uuidString: userIdString) else {
            throw RepositoryError.notAuthenticated
        }

        let feedback: [RecommendationFeedback] = try await restClient.post(
            table: "recommendation_feedback",
            body: RecommendationFeedbackPayload(userId: userId, input: input)
        )

        guard let savedFeedback = feedback.first else {
            throw RepositoryError.server(statusCode: 204, message: "Feedback insert returned no row.")
        }

        return savedFeedback
    }
}

struct RecommendationFeedbackInput: Equatable, Sendable {
    var recommendationId: UUID
    var feedbackType: FeedbackType
    var garmentId: UUID?
    var notes: String?
}

private struct RecommendationFeedbackPayload: Encodable {
    let userId: UUID
    let recommendationId: UUID
    let feedbackType: FeedbackType
    let garmentId: UUID?
    let notes: String?

    init(userId: UUID, input: RecommendationFeedbackInput) {
        self.userId = userId
        recommendationId = input.recommendationId
        feedbackType = input.feedbackType
        garmentId = input.garmentId
        notes = input.notes
    }

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case recommendationId = "recommendation_id"
        case feedbackType = "feedback_type"
        case garmentId = "garment_id"
        case notes
    }
}
