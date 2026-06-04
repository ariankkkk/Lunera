import Foundation
import XCTest
@testable import Lunera

final class ModelDecodingTests: XCTestCase {
    func testProfileDecodesSupabaseTimestamps() throws {
        let json = """
        {
          "id": "11111111-1111-1111-1111-111111111111",
          "username": "arian",
          "display_name": "Arian",
          "avatar_url": null,
          "home_city": "Baku",
          "created_at": "2026-06-05T00:00:00.000Z",
          "updated_at": "2026-06-05T00:10:00.000Z"
        }
        """.data(using: .utf8)!

        let profile = try JSONDecoder.luneraSupabase.decode(Profile.self, from: json)

        XCTAssertEqual(profile.username, "arian")
        XCTAssertEqual(profile.homeCity, "Baku")
    }

    func testEventRecordDecodesDateOnlyEventDate() throws {
        let json = """
        {
          "id": "22222222-2222-2222-2222-222222222222",
          "user_id": "11111111-1111-1111-1111-111111111111",
          "title": "Dinner",
          "description": "Smart dinner",
          "event_date": "2026-06-05",
          "location_text": "Baku",
          "image_url": null,
          "event_context": { "dress_code": "smart_casual" },
          "created_at": "2026-06-05T00:00:00Z",
          "updated_at": "2026-06-05T00:10:00Z"
        }
        """.data(using: .utf8)!

        let event = try JSONDecoder.luneraSupabase.decode(EventRecord.self, from: json)

        XCTAssertEqual(event.title, "Dinner")
        XCTAssertEqual(event.eventContext["dress_code"], .string("smart_casual"))
        XCTAssertNotNil(event.eventDate)
    }
}
