import XCTest
@testable import VerifiKit

extension Rule {

    func assertFails(for value: T, with expectedReason: String? = nil, file: StaticString = #file, line: UInt = #line) {
        _ = test(value, SingleTest(pass: {
            XCTFail(file: file, line: line)
            return true
        }, fail: { reason in
            if let expectedReason = expectedReason {
                XCTAssertEqual(reason, expectedReason, file: file, line: line)
            }
            return false
        }))
    }

    func assertPasses(for value: T, file: StaticString = #file, line: UInt = #line) {
        _ = test(value, SingleTest(pass: {
            return true
        }, fail: { reason in
            XCTFail(file: file, line: line)
            return false
        }))
    }
}
