import XCTest
import PeekKit

class Tests: XCTestCase {

    func testOnlyHttpsCountsAsSecure() {
        XCTAssertTrue(isSecurePage(URL(string: "https://example.com")!))
        XCTAssertFalse(isSecurePage(URL(string: "http://example.com")!))
    }

    func testPeekerCanBeCreated() {
        measure {
            _ = Peeker()
        }
    }
}
