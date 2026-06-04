import Foundation

struct EventScoringContext: Equatable, Sendable {
    var dressCode: String?
    var formality: Double?
    var moodTags: [String]
    var colorHints: [String]

    init(
        dressCode: String? = nil,
        formality: Double? = nil,
        moodTags: [String] = [],
        colorHints: [String] = []
    ) {
        self.dressCode = dressCode
        self.formality = formality
        self.moodTags = moodTags
        self.colorHints = colorHints
    }
}

struct RecommendationScoringSignals: Equatable, Sendable {
    var rejectedGarmentIds: Set<UUID> = []
    var likedStyleTags: Set<String> = []
}

struct RecommendationScore: Equatable, Sendable {
    var total: Double
    var size: Double
    var stock: Double
    var style: Double
    var event: Double
    var colorBrand: Double
    var price: Double
    var feedback: Double
    var reasonCodes: [String]
    var stockWarnings: [String]
}

enum RecommendationScorer {
    static func score(
        garment: Garment,
        preferences: UserPreferenceInput,
        stockSnapshots: [StockSnapshot],
        eventContext: EventScoringContext = EventScoringContext(),
        signals: RecommendationScoringSignals = RecommendationScoringSignals(),
        now: Date = Date()
    ) -> RecommendationScore {
        if isBlocked(garment: garment, preferences: preferences) {
            return RecommendationScore(
                total: 0,
                size: 0,
                stock: 0,
                style: 0,
                event: 0,
                colorBrand: 0,
                price: 0,
                feedback: 0,
                reasonCodes: ["blocked_item"],
                stockWarnings: []
            )
        }

        var reasonCodes: [String] = []
        var stockWarnings: [String] = []

        let preferredSizes = preferredSizes(from: preferences)
        let sizeScore = scoreSize(garment: garment, preferredSizes: preferredSizes, reasonCodes: &reasonCodes)
        let stockScore = scoreStock(
            snapshots: stockSnapshots,
            preferredSizes: preferredSizes,
            now: now,
            reasonCodes: &reasonCodes,
            stockWarnings: &stockWarnings
        )
        let styleScore = scoreOverlap(
            candidate: garment.styleTags,
            preferred: preferences.styleTags,
            maxScore: 20,
            matchReason: "style_match",
            reasonCodes: &reasonCodes
        )
        let eventScore = scoreEvent(garment: garment, eventContext: eventContext, reasonCodes: &reasonCodes)
        let colorBrandScore = scoreColorAndBrand(garment: garment, preferences: preferences, eventContext: eventContext, reasonCodes: &reasonCodes)
        let priceScore = scorePrice(garment: garment, preferences: preferences, reasonCodes: &reasonCodes)
        let feedbackScore = scoreFeedback(garment: garment, signals: signals, reasonCodes: &reasonCodes)
        let total = sizeScore + stockScore + styleScore + eventScore + colorBrandScore + priceScore + feedbackScore

        return RecommendationScore(
            total: min(100, max(0, total)),
            size: sizeScore,
            stock: stockScore,
            style: styleScore,
            event: eventScore,
            colorBrand: colorBrandScore,
            price: priceScore,
            feedback: feedbackScore,
            reasonCodes: orderedUnique(reasonCodes),
            stockWarnings: stockWarnings
        )
    }

    private static func isBlocked(garment: Garment, preferences: UserPreferenceInput) -> Bool {
        if let color = garment.color?.lowercased(), preferences.blockedColors.map({ $0.lowercased() }).contains(color) {
            return true
        }

        if let brand = garment.brand?.lowercased(), preferences.blockedBrands.map({ $0.lowercased() }).contains(brand) {
            return true
        }

        return false
    }

    private static func preferredSizes(from preferences: UserPreferenceInput) -> Set<String> {
        var sizes = Set<String>()

        for value in preferences.sizes.values {
            collectSizes(from: value, into: &sizes)
        }

        return sizes
    }

    private static func collectSizes(from value: JSONValue, into sizes: inout Set<String>) {
        switch value {
        case .string(let size):
            sizes.insert(size.uppercased())
        case .array(let values):
            values.forEach { collectSizes(from: $0, into: &sizes) }
        case .object(let values):
            values.values.forEach { collectSizes(from: $0, into: &sizes) }
        case .number, .bool, .null:
            break
        }
    }

    private static func scoreSize(garment: Garment, preferredSizes: Set<String>, reasonCodes: inout [String]) -> Double {
        guard !preferredSizes.isEmpty else {
            return 12.5
        }

        let availableSizes = Set(garment.availableSizes.map { $0.uppercased() })
        guard !availableSizes.isDisjoint(with: preferredSizes) else {
            reasonCodes.append("unavailable_size")
            return 0
        }

        reasonCodes.append("size_match")
        return 25
    }

    private static func scoreStock(
        snapshots: [StockSnapshot],
        preferredSizes: Set<String>,
        now: Date,
        reasonCodes: inout [String],
        stockWarnings: inout [String]
    ) -> Double {
        let relevantSnapshots = snapshots
            .filter { preferredSizes.isEmpty || preferredSizes.contains($0.size.uppercased()) }
            .sorted { $0.observedAt > $1.observedAt }

        guard let snapshot = relevantSnapshots.first else {
            stockWarnings.append("No recent stock snapshot is available.")
            return 4
        }

        let age = now.timeIntervalSince(snapshot.observedAt)
        let freshnessMultiplier = age <= 24 * 60 * 60 ? 1.0 : 0.5
        if freshnessMultiplier < 1 {
            stockWarnings.append("Stock snapshot is older than 24 hours.")
        }

        switch snapshot.stockState {
        case .inStock:
            reasonCodes.append("stock_available")
            return 20 * freshnessMultiplier
        case .lowStock:
            reasonCodes.append("stock_limited")
            return 14 * freshnessMultiplier
        case .unknown:
            stockWarnings.append("Stock state is unknown.")
            return 6 * freshnessMultiplier
        case .outOfStock:
            stockWarnings.append("Preferred size is currently marked out of stock.")
            return 0
        }
    }

    private static func scoreOverlap(
        candidate: [String],
        preferred: [String],
        maxScore: Double,
        matchReason: String,
        reasonCodes: inout [String]
    ) -> Double {
        guard !preferred.isEmpty else {
            return maxScore * 0.5
        }

        let candidateSet = Set(candidate.map { $0.lowercased() })
        let preferredSet = Set(preferred.map { $0.lowercased() })
        let matches = candidateSet.intersection(preferredSet).count
        guard matches > 0 else {
            return 0
        }

        reasonCodes.append(matchReason)
        return maxScore * min(1, Double(matches) / Double(preferredSet.count))
    }

    private static func scoreEvent(garment: Garment, eventContext: EventScoringContext, reasonCodes: inout [String]) -> Double {
        var score = 7.5
        let garmentTags = Set((garment.styleTags + garment.seasonTags + [garment.category]).map { $0.lowercased() })
        let eventTags = Set((eventContext.moodTags + [eventContext.dressCode].compactMap { $0 }).map { $0.lowercased() })

        if !eventTags.isEmpty, !garmentTags.isDisjoint(with: eventTags) {
            score += 5
            reasonCodes.append("event_match")
        }

        if let formality = eventContext.formality {
            let formalTags = ["formal", "elegant", "tailored", "smart_casual"]
            let casualTags = ["casual", "streetwear", "sport"]
            if formality >= 0.65, !garmentTags.isDisjoint(with: formalTags) {
                score += 2.5
            } else if formality < 0.65, !garmentTags.isDisjoint(with: casualTags) {
                score += 2.5
            }
        }

        return min(15, score)
    }

    private static func scoreColorAndBrand(
        garment: Garment,
        preferences: UserPreferenceInput,
        eventContext: EventScoringContext,
        reasonCodes: inout [String]
    ) -> Double {
        var score = 0.0

        if let color = garment.color?.lowercased() {
            if preferences.preferredColors.map({ $0.lowercased() }).contains(color) {
                score += 5
                reasonCodes.append("color_match")
            }

            if eventContext.colorHints.map({ $0.lowercased() }).contains(color) {
                score += 2
                reasonCodes.append("event_color_match")
            }
        }

        if let brand = garment.brand?.lowercased(), preferences.preferredBrands.map({ $0.lowercased() }).contains(brand) {
            score += 5
            reasonCodes.append("brand_match")
        }

        return min(10, score)
    }

    private static func scorePrice(garment: Garment, preferences: UserPreferenceInput, reasonCodes: inout [String]) -> Double {
        guard let price = garment.price else {
            return 2.5
        }

        if let minPrice = preferences.priceMin, price < minPrice {
            return 2
        }

        if let maxPrice = preferences.priceMax, price > maxPrice {
            return 0
        }

        reasonCodes.append("price_match")
        return 5
    }

    private static func scoreFeedback(
        garment: Garment,
        signals: RecommendationScoringSignals,
        reasonCodes: inout [String]
    ) -> Double {
        if signals.rejectedGarmentIds.contains(garment.id) {
            reasonCodes.append("rejected_item_penalty")
            return -20
        }

        let likedOverlap = Set(garment.styleTags.map { $0.lowercased() }).intersection(signals.likedStyleTags.map { $0.lowercased() })
        if !likedOverlap.isEmpty {
            reasonCodes.append("feedback_style_boost")
            return 5
        }

        return 0
    }

    private static func orderedUnique(_ values: [String]) -> [String] {
        var seen = Set<String>()
        var result: [String] = []

        for value in values where !seen.contains(value) {
            seen.insert(value)
            result.append(value)
        }

        return result
    }
}
