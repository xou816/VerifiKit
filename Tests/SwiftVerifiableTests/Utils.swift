import XCTest
@testable import SwiftVerifiable

extension Rule {

    func assertFails(for value: T, with expectedReason: String? = nil) {
        _ = test(value, ComplianceTest(pass: {
            XCTFail()
            return true
        }, fail: { reason in
            if let expectedReason = expectedReason {
                XCTAssertEqual(reason, expectedReason)
            }
            return false
        }))
    }

    func assertPasses(for value: T) {
        _ = test(value, ComplianceTest(pass: {
            return true
        }, fail: { reason in
            XCTFail()
            return false
        }))
    }
}
