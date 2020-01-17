fileprivate struct MiscRules {
    
    static let bePositiveInteger: Rule<Int> = Rule { (int, test) in
        int >= 0 ? test.pass() : test.fail("\(int) is not a positive integer")
    }
    
    static let notBeEmptyString: Rule<String> = Rule { (str, test) in
        str.isEmpty ? test.fail("Provided string is empty") : test.pass()
    }

    static let notBeBlankString: Rule<String> = Rule { (str, test) in
        str.trimmingCharacters(in: .whitespaces).isEmpty ? test.fail("Provided string is blank") : test.pass()
    }

    static func beOfLength(_ len: Int) -> Rule<String> {
        return Rule { (str, test) in 
            str.count == len ? test.pass() : test.fail("'\(str)' is not \(len) characters long")
        }
    }

    static func matchRegex(_ regex: String, failMessage: String? = nil) -> Rule<String> {
        return Rule { (str, test) in
            let range = str.range(of: regex, options: .regularExpression)
            if case .some = range {
                return test.pass()
            } else {
                let failMessage = failMessage.map { String(format: $0, arguments: [str]) }
                return test.fail(failMessage ?? "'\(str)' does not match expression")
            }
        }
    }
}

extension Rule {
    public static var bePositiveInteger: Rule<Int> { MiscRules.bePositiveInteger }
    public static var notBeEmptyString: Rule<String> { MiscRules.notBeEmptyString }
    public static var notBeBlankString: Rule<String> { MiscRules.notBeBlankString }
    public static var beEmptyString: Rule<String> { .not(MiscRules.notBeEmptyString, failMessage: "Provided string is not empty") }
    public static var beBlankString: Rule<String> { .not(MiscRules.notBeBlankString, failMessage: "Provided string is not blank") }
    public static func beOfLength(_ len: Int) -> Rule<String> { MiscRules.beOfLength(len) }
    public static func matchRegex(_ regex: String, failMessage: String? = nil) -> Rule<String> { MiscRules.matchRegex(regex, failMessage: failMessage) }
}
