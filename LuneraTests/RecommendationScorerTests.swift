import Foundation
import XCTest
@testable import Lunera

final class RecommendationScorerTests: XCTestCase {
    func testPreferenceMatchBeatsGenericItem() {
        let now = Date(timeIntervalSince1970: 1_780_607_000)
        let preference = UserPreferenceInput(
            sizes: ["tops": .array([.string("M")])],
            preferredColors: ["cream"],
            preferredBrands: ["Lunera"],
            priceMin: nil,
            priceMax: 120,
            styleTags: ["elegant"]
        )

        let matched = makeGarment(
            id: UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa")!,
            brand: "Lunera",
            color: "cream",
            styleTags: ["elegant"],
            availableSizes: ["M"],
            price: 90
        )
        let generic = makeGarment(
            id: UUID(uuidString: "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb")!,
            brand: "Other",
            color: "black",
            styleTags: ["casual"],
            availableSizes: ["M"],
            price: 90
        )

        let matchedScore = RecommendationScorer.score(
            garment: matched,
            preferences: preference,
            stockSnapshots: [makeSnapshot(garmentId: matched.id, size: "M", state: .inStock, observedAt: now)],
            eventContext: EventScoringContext(dressCode: "smart_casual", formality: 0.7, moodTags: ["elegant"]),
            now: now
        )
        let genericScore = RecommendationScorer.score(
            garment: generic,
            preferences: preference,
            stockSnapshots: [makeSnapshot(garmentId: generic.id, size: "M", state: .inStock, observedAt: now)],
            now: now
        )

        XCTAssertGreaterThan(matchedScore.total, genericScore.total)
        XCTAssertTrue(matchedScore.reasonCodes.contains("style_match"))
    }

    func testUnavailableSizePenaltyLowersScore() {
        let now = Date(timeIntervalSince1970: 1_780_607_000)
        let preference = UserPreferenceInput(sizes: ["tops": .array([.string("M")])])
        let garment = makeGarment(availableSizes: ["S"], price: 50)

        let score = RecommendationScorer.score(
            garment: garment,
            preferences: preference,
            stockSnapshots: [makeSnapshot(garmentId: garment.id, size: "S", state: .inStock, observedAt: now)],
            now: now
        )

        XCTAssertEqual(score.size, 0)
        XCTAssertTrue(score.reasonCodes.contains("unavailable_size"))
    }

    func testRejectedItemReceivesPenalty() {
        let garment = makeGarment(styleTags: ["elegant"], availableSizes: ["M"], price: 70)
        let preference = UserPreferenceInput(sizes: ["tops": .string("M")], styleTags: ["elegant"])

        let score = RecommendationScorer.score(
            garment: garment,
            preferences: preference,
            stockSnapshots: [],
            signals: RecommendationScoringSignals(rejectedGarmentIds: [garment.id])
        )

        XCTAssertLessThan(score.feedback, 0)
        XCTAssertTrue(score.reasonCodes.contains("rejected_item_penalty"))
    }

    private func makeGarment(
        id: UUID = UUID(uuidString: "33333333-3333-3333-3333-333333333333")!,
        brand: String? = "Lunera",
        color: String? = "cream",
        styleTags: [String] = ["elegant"],
        availableSizes: [String] = ["M"],
        price: Decimal? = 90
    ) -> Garment {
        let date = Date(timeIntervalSince1970: 1_780_607_000)
        return Garment(
            id: id,
            brand: brand,
            name: "Cardigan",
            category: "top",
            subcategory: nil,
            color: color,
            styleTags: styleTags,
            seasonTags: [],
            sizeSystem: "alpha",
            availableSizes: availableSizes,
            price: price,
            currency: "AZN",
            imageURL: nil,
            sourceURL: nil,
            metadata: [:],
            createdAt: date,
            updatedAt: date
        )
    }

    private func makeSnapshot(
        garmentId: UUID,
        size: String,
        state: StockState,
        observedAt: Date
    ) -> StockSnapshot {
        StockSnapshot(
            id: UUID(),
            garmentId: garmentId,
            storeId: UUID(uuidString: "44444444-4444-4444-4444-444444444444")!,
            size: size,
            stockState: state,
            quantity: nil,
            observedAt: observedAt,
            sourceId: nil,
            sourceURL: nil,
            confidence: 0.9,
            rawPayload: [:]
        )
    }
}
