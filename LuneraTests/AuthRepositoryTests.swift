import Foundation
import XCTest
@testable import Lunera

final class AuthRepositoryTests: XCTestCase {
    func testUsernameNormalizesAndMapsToInternalEmail() {
        let username = UsernameAuthMapper.normalize(" Arian.K_ ")

        XCTAssertEqual(username, "arian.k_")
        XCTAssertTrue(UsernameAuthMapper.isValidUsername(username))
        XCTAssertEqual(UsernameAuthMapper.authEmail(for: username), "arian-dot-k-under-@users.lunera.app")
    }

    func testUsernameValidationRejectsShortAndUnsafeValues() {
        XCTAssertFalse(UsernameAuthMapper.isValidUsername("ar"))
        XCTAssertFalse(UsernameAuthMapper.isValidUsername("arian!"))
        XCTAssertFalse(UsernameAuthMapper.isValidUsername(String(repeating: "a", count: 25)))
    }

    func testAuthErrorMapperMapsInvalidCredentials() throws {
        let data = try JSONSerialization.data(withJSONObject: [
            "message": "Invalid login credentials"
        ])

        let error = SupabaseAuthErrorMapper.map(data: data, statusCode: 400)

        XCTAssertEqual(error, .wrongPassword)
    }
}
