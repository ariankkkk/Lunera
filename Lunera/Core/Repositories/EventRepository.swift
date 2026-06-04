import Foundation

final class EventRepository {
    private let restClient: SupabaseRESTClient
    private let authRepository: AuthRepository

    init(restClient: SupabaseRESTClient = SupabaseRESTClient(), authRepository: AuthRepository = .shared) {
        self.restClient = restClient
        self.authRepository = authRepository
    }

    func fetchEvents() async throws -> [EventRecord] {
        guard let userId = authRepository.currentSession?.userId else {
            throw RepositoryError.notAuthenticated
        }

        return try await restClient.get(
            table: "events",
            queryItems: [
                URLQueryItem(name: "select", value: "*"),
                URLQueryItem(name: "user_id", value: "eq.\(userId)"),
                URLQueryItem(name: "order", value: "created_at.desc")
            ]
        )
    }

    func createEvent(_ input: EventInput) async throws -> EventRecord {
        guard let userIdString = authRepository.currentSession?.userId,
              let userId = UUID(uuidString: userIdString) else {
            throw RepositoryError.notAuthenticated
        }

        let events: [EventRecord] = try await restClient.post(
            table: "events",
            body: EventPayload(userId: userId, input: input)
        )

        guard let event = events.first else {
            throw RepositoryError.server(statusCode: 204, message: "Event creation returned no row.")
        }

        return event
    }
}

struct EventInput: Equatable, Sendable {
    var title: String
    var description: String?
    var eventDate: Date?
    var locationText: String?
    var imageURL: URL?
    var eventContext: [String: JSONValue] = [:]
}

private struct EventPayload: Encodable {
    let userId: UUID
    let title: String
    let description: String?
    let eventDate: Date?
    let locationText: String?
    let imageURL: URL?
    let eventContext: [String: JSONValue]

    init(userId: UUID, input: EventInput) {
        self.userId = userId
        title = input.title
        description = input.description
        eventDate = input.eventDate
        locationText = input.locationText
        imageURL = input.imageURL
        eventContext = input.eventContext
    }

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case title
        case description
        case eventDate = "event_date"
        case locationText = "location_text"
        case imageURL = "image_url"
        case eventContext = "event_context"
    }
}
