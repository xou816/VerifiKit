import XCTest

import SwiftVerifiableTests

var tests = [XCTestCaseEntry]()
tests += SwiftVerifiableTests.allTests()
XCTMain(tests)
