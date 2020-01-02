import XCTest
@testable import VerifiKit

fileprivate struct Test {
    
    struct Client: Verifiable {

        @Should(.notBeEmptyString)
        var name: String?

        init() {}
    }
    
    struct ClientStrict: Verifiable {

        @Must(.notBeEmptyString)
        var name: String
        
        init() {}
    }

    struct Basket: Verifiable {

        @Must(.bePositiveInteger)
        var amount: Int
        
        var client: ClientStrict
        var version: String
        
        init() {
            self.client = ClientStrict()
            self.version = "1"
        }
    }
}


final class VerifiKitTests: XCTestCase {

	func test_propMarkedShouldCannotHoldInvalidValues() {
        let client = Test.Client()
		client.name = ""
        let rule: Rule<String> = .notBeEmptyString
        rule.assertFails(for: "")
        XCTAssertNil(client.name)
	}
    
    func test_propMarkedShouldCanHoldValidValues() {
        let client = Test.Client()
        client.name = "toto"
        let rule: Rule<String> = .notBeEmptyString
        rule.assertPasses(for: "toto")
        XCTAssertEqual(client.name, "toto")
    }
    
    func test_propMarkedMustCanHoldValidValues() {
        let basket = Test.Basket()
        basket.amount = 2
        let rule: Rule<Int> = .bePositiveInteger
        rule.assertPasses(for: 2)
        XCTAssertEqual(basket.amount, 2)
    }

    func test_rulesCanBeCombined() {
        let rule: Rule<String> = .notBeBlankString & .beOfLength(3)
        rule.assertFails(for: "ab", with: "'ab' is not 3 characters long")
        rule.assertFails(for: "", with: "Provided string is blank")
        rule.assertPasses(for: "abc")

        let ruleInverted: Rule<String> = .beOfLength(3) & .notBeBlankString
        ruleInverted.assertFails(for: "", with: "'' is not 3 characters long")

        let rule2: Rule<String> = .beEmptyString | .beOfLength(3)
        rule2.assertFails(for: "ab", with: "Provided string is not empty; 'ab' is not 3 characters long")
        rule2.assertPasses(for: "")
        rule2.assertPasses(for: "abc")
    }
    
    func test_hasReasonWhenFailing() {
        let rule: Rule<Bool> = .failing(reason: "failure reason")
        rule.assertFails(for: true, with: "failure reason")
    }

	func test_verifiableAllowsRetrievingRules() {
		let basket = Test.Basket()
		if let rule: Rule<Int> = basket.getRuleFor(key: "amount") {
            rule.assertFails(for: -2)
            rule.assertPasses(for: 2)
		}
	}

	func test_verifiableAllowsRetrievingNestedRules() {
		let basket = Test.Basket()
		if let rule: Rule<String> = basket.getRuleFor(path: ["client", "name"]) {
            rule.assertFails(for: "")
            rule.assertPasses(for: "foo")
		}
	}
    
    func test_decodingInvalidObjectWithMustMarkerThrows() {
        let basketInvalid = #"{"amount": -2, "version": "1", "client": {"name": "toto"}}"#.data(using: .utf8)!
        do {
            _ = try JSONDecoder().decode(verify: Test.Basket.self, from: basketInvalid)
            XCTFail()
        } catch VerificationError.rulesBroken(let rules) {
            XCTAssertEqual(rules.first!.path, "amount")
            XCTAssertEqual(rules.first!.reason, "-2 is not a positive integer")
        } catch {
            XCTFail()
        }
    }
    
    func test_decodingIsRecursive() {
        let basketInvalid = #"{"amount": -2, "version": "1", "client": {"name": ""}}"#.data(using: .utf8)!
        do {
            _ = try JSONDecoder().decode(verify: Test.Basket.self, from: basketInvalid)
            XCTFail()
        } catch VerificationError.rulesBroken(let rules) {
            XCTAssertEqual(rules.count, 2)
            XCTAssertEqual(rules[0].path, "amount")
            XCTAssertEqual(rules[0].reason, "-2 is not a positive integer")
            XCTAssertEqual(rules[1].path, "client.name")
            XCTAssertEqual(rules[1].reason, "Provided string is empty")
        } catch {
            XCTFail()
        }
    }
    
    func test_decodingInvalidObjectWithShouldMarkerDoesNotThrowUnlessStrict() {
        let clientInvalid = #"{"name": ""}"#.data(using: .utf8)!
        if let client = try? JSONDecoder().decode(verify: Test.Client.self, from: clientInvalid) {
            XCTAssertNil(client.name)
        }
        do {
            _ = try JSONDecoder().decode(verifyStrict: Test.Client.self, from: clientInvalid)
            XCTFail()
        } catch VerificationError.rulesBroken(let rules) {
            XCTAssertEqual(rules.count, 1)
            XCTAssertEqual(rules.first!.path, "name")
            XCTAssertEqual(rules.first!.reason, "Provided string is empty")
        } catch {
            XCTFail()
        }
    }
    
    func test_verifyCanBeUsedToTestAssignments() {
        let basket = Test.Basket()
        basket.client.name = "old name"
        do {
            try verify(basket) {
                basket.amount = -1
                basket.amount = -2
                basket.client.name = "new name"
            }
            XCTFail()
        } catch VerificationError.rulesBroken(let rules) {
            XCTAssertEqual(rules.count, 2)
            XCTAssertEqual(rules[0].path, "amount")
            XCTAssertEqual(rules[1].path, "amount")
            XCTAssertEqual(rules[0].reason, "-1 is not a positive integer")
            XCTAssertEqual(rules[1].reason, "-2 is not a positive integer")
        } catch {
            XCTFail()
        }
        XCTAssertEqual(basket.client.name, "old name")
        
    }
        
    func test_verifyingInvalidObjectWithShouldMarkerDoesNotThrowUnlessStrict() {
        let client = Test.Client()
        do {
           try verify(client) { client.name = "" }
        } catch {
            XCTFail()
        }
        XCTAssertNil(client.name)
        do {
           try verifyStrict(client) { client.name = "" }
        } catch VerificationError.rulesBroken(let rules) {
            XCTAssertEqual(rules.count, 1)
            XCTAssertEqual(rules.first!.path, "name")
            XCTAssertEqual(rules.first!.reason, "Provided string is empty")
        } catch {
            XCTFail()
        }
    }

	static var allTests = [
        ("test_propMarkedShouldCannotHoldInvalidValues", test_propMarkedShouldCannotHoldInvalidValues),
		("test_propMarkedShouldCanHoldValidValues", test_propMarkedShouldCanHoldValidValues),
        ("test_propMarkedMustCanHoldValidValues", test_propMarkedMustCanHoldValidValues),
        ("test_rulesCanBeCombined", test_rulesCanBeCombined),
        ("test_hasReasonWhenFailing", test_hasReasonWhenFailing),
		("test_verifiableAllowsRetrievingRules", test_verifiableAllowsRetrievingRules),
		("test_verifiableAllowsRetrievingNestedRules", test_verifiableAllowsRetrievingNestedRules),
        ("test_decodingInvalidObjectWithMustMarkerThrows", test_decodingInvalidObjectWithMustMarkerThrows),
        ("test_decodingIsRecursive", test_decodingIsRecursive),
        ("test_decodingInvalidObjectWithShouldMarkerDoesNotThrowUnlessStrict", test_decodingInvalidObjectWithShouldMarkerDoesNotThrowUnlessStrict),
        ("test_verifyCanBeUsedToTestAssignments", test_verifyCanBeUsedToTestAssignments),
        ("test_verifyingInvalidObjectWithShouldMarkerDoesNotThrowUnlessStrict", test_verifyingInvalidObjectWithShouldMarkerDoesNotThrowUnlessStrict)
	]
}
