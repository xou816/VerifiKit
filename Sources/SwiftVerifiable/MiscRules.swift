fileprivate struct MiscRules {
    
    static let bePositiveInteger: Rule<Int> = Rule { (int, test) in
        int >= 0 ? test.pass() : test.fail("Expected positive integer")
    }
    
    static let beNotEmptyString: Rule<String> = Rule { (str, test) in
        str.isEmpty ? test.fail("Unexpected empty string") : test.pass()
    }
}

extension Rule {
    static var bePositiveInteger: Rule<Int> { MiscRules.bePositiveInteger }
    static var beNotEmptyString: Rule<String> { MiscRules.beNotEmptyString }
}
