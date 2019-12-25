fileprivate struct MiscRules {
    
    static let bePositiveInteger: Rule<Int> = Rule { (int, test) in
        int >= 0 ? test.pass() : test.fail("\(int) is not a positive integer")
    }
    
    static let beNotEmptyString: Rule<String> = Rule { (str, test) in
        str.isEmpty ? test.fail("Provided string is empty") : test.pass()
    }

    static let beNotBlankString: Rule<String> = Rule { (str, test) in
        str.trimmingCharacters(in: .whitespaces).isEmpty ? test.fail("Provided string is blank") : test.pass()
    }

    static let beEmptyString: Rule<String> = Rule { (str, test) in
        str.isEmpty ? test.pass() : test.fail("Provided string is not empty")
    }

    static let beBlankString: Rule<String> = Rule { (str, test) in
        str.trimmingCharacters(in: .whitespaces).isEmpty ? test.pass() : test.fail("Provided string is not blank")
    }

    static func beOfLength(_ len: Int) -> Rule<String> {
        return Rule { (str, test) in 
            str.count == len ? test.pass() : test.fail("'\(str)' is not \(len) characters long")
        }
    }
}

extension Rule {
    static var bePositiveInteger: Rule<Int> { MiscRules.bePositiveInteger }
    static var beNotEmptyString: Rule<String> { MiscRules.beNotEmptyString }
    static var beNotBlankString: Rule<String> { MiscRules.beNotBlankString }
    static var beEmptyString: Rule<String> { MiscRules.beEmptyString }
    static var beBlankString: Rule<String> { MiscRules.beBlankString }
    static func beOfLength(_ len: Int) -> Rule<String> { MiscRules.beOfLength(len) }
}
