import Foundation

struct Profile: Codable, Identifiable, Equatable, Sendable {
    let id: UUID
    var username: String?
    var displayName: String?
    var avatarURL: URL?
    var homeCity: String
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case username
        case displayName = "display_name"
        case avatarURL = "avatar_url"
        case homeCity = "home_city"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct UserPreference: Codable, Identifiable, Equatable, Sendable {
    let id: UUID
    var userId: UUID
    var sizes: [String: JSONValue]
    var preferredColors: [String]
    var blockedColors: [String]
    var preferredBrands: [String]
    var blockedBrands: [String]
    var priceMin: Decimal?
    var priceMax: Decimal?
    var preferredStoreIds: [UUID]
    var styleTags: [String]
    var fitPreferences: [String]
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
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
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct Garment: Codable, Identifiable, Equatable, Sendable {
    let id: UUID
    var brand: String?
    var name: String
    var category: String
    var subcategory: String?
    var color: String?
    var styleTags: [String]
    var seasonTags: [String]
    var sizeSystem: String?
    var availableSizes: [String]
    var price: Decimal?
    var currency: String
    var imageURL: URL?
    var sourceURL: URL?
    var metadata: [String: JSONValue]
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case brand
        case name
        case category
        case subcategory
        case color
        case styleTags = "style_tags"
        case seasonTags = "season_tags"
        case sizeSystem = "size_system"
        case availableSizes = "available_sizes"
        case price
        case currency
        case imageURL = "image_url"
        case sourceURL = "source_url"
        case metadata
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct Store: Codable, Identifiable, Equatable, Sendable {
    let id: UUID
    var name: String
    var brand: String?
    var city: String
    var address: String?
    var sourceId: String?
    var sourceType: String
    var sourceConfig: [String: JSONValue]
    var isActive: Bool
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case brand
        case city
        case address
        case sourceId = "source_id"
        case sourceType = "source_type"
        case sourceConfig = "source_config"
        case isActive = "is_active"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct StockSnapshot: Codable, Identifiable, Equatable, Sendable {
    let id: UUID
    var garmentId: UUID
    var storeId: UUID
    var size: String
    var stockState: StockState
    var quantity: Int?
    var observedAt: Date
    var sourceId: String?
    var sourceURL: URL?
    var confidence: Decimal?
    var rawPayload: [String: JSONValue]

    enum CodingKeys: String, CodingKey {
        case id
        case garmentId = "garment_id"
        case storeId = "store_id"
        case size
        case stockState = "stock_state"
        case quantity
        case observedAt = "observed_at"
        case sourceId = "source_id"
        case sourceURL = "source_url"
        case confidence
        case rawPayload = "raw_payload"
    }
}

enum StockState: String, Codable, Equatable, Sendable {
    case inStock = "in_stock"
    case lowStock = "low_stock"
    case outOfStock = "out_of_stock"
    case unknown
}

struct EventRecord: Codable, Identifiable, Equatable, Sendable {
    let id: UUID
    var userId: UUID
    var title: String
    var description: String?
    var eventDate: Date?
    var locationText: String?
    var imageURL: URL?
    var eventContext: [String: JSONValue]
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case title
        case description
        case eventDate = "event_date"
        case locationText = "location_text"
        case imageURL = "image_url"
        case eventContext = "event_context"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct OutfitRecommendation: Codable, Identifiable, Equatable, Sendable {
    let id: UUID
    var userId: UUID
    var eventId: UUID?
    var status: RecommendationStatus
    var recommendedItems: [RecommendedItem]
    var scoreBreakdown: [String: JSONValue]
    var reasonCodes: [String]
    var stockWarnings: [String]
    var confidence: Decimal?
    var userFacingExplanation: String?
    var modelVersion: String?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case eventId = "event_id"
        case status
        case recommendedItems = "recommended_items"
        case scoreBreakdown = "score_breakdown"
        case reasonCodes = "reason_codes"
        case stockWarnings = "stock_warnings"
        case confidence
        case userFacingExplanation = "user_facing_explanation"
        case modelVersion = "model_version"
        case createdAt = "created_at"
    }
}

enum RecommendationStatus: String, Codable, Equatable, Sendable {
    case draft
    case generated
    case shown
    case saved
    case dismissed
    case failed
}

struct RecommendedItem: Codable, Equatable, Sendable {
    var garmentId: UUID
    var role: String
    var reasonCodes: [String]
    var displayReason: String?

    enum CodingKeys: String, CodingKey {
        case garmentId = "garment_id"
        case role
        case reasonCodes = "reason_codes"
        case displayReason = "display_reason"
    }
}

struct RecommendationFeedback: Codable, Identifiable, Equatable, Sendable {
    let id: UUID
    var userId: UUID
    var recommendationId: UUID
    var feedbackType: FeedbackType
    var garmentId: UUID?
    var notes: String?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case recommendationId = "recommendation_id"
        case feedbackType = "feedback_type"
        case garmentId = "garment_id"
        case notes
        case createdAt = "created_at"
    }
}

enum FeedbackType: String, Codable, Equatable, Sendable {
    case like
    case dislike
    case hideItem = "hide_item"
    case chosen
    case notes
}
