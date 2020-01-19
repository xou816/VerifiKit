extension TestProxy {

    func allPass<T>(value: T, rules: Rule<T>...) -> Bool {
        let result = rules
            .reduce(true) { (result, rule) in result && rule.test(value, self) }
        return result ? actualTest.pass() : actualTest.fail(reason)
    }

    func anyPass<T>(value: T, rules: Rule<T>...) -> Bool {
        let result = rules
            .reduce(false) { (result, rule) in result || rule.test(value, self) }
        return result ? actualTest.pass() : actualTest.fail(reason)
    }

    func notPass<T>(value: T, rule: Rule<T>, failMessage: String? = nil) -> Bool {
        let result = rule.test(value, self)
        let failMessage = failMessage.map { String(format: $0, sub1: "\(value)") }
        return result ? actualTest.fail(failMessage ?? "Expected test not to pass") : actualTest.pass()
    }
}

extension Rule {

    public static func not<T>(_ rule: Rule<T>, failMessage: String? = nil) -> Rule<T> {
        return Rule<T> { (t, test) in
            let proxy = TestProxy(wrap: test)
            return proxy.notPass(value: t, rule: rule, failMessage: failMessage)
        }
    }

}

public func &<T>(_ lhs: Rule<T>, _ rhs: Rule<T>) -> Rule<T> {
    return Rule { (t, test) in
        let proxy = TestProxy(wrap: test)
        return proxy.allPass(value: t, rules: lhs, rhs)
    }
}

public func |<T>(_ lhs: Rule<T>, _ rhs: Rule<T>) -> Rule<T> {
    return Rule { (t, test) in
        let proxy = TestProxy(wrap: test)
        return proxy.anyPass(value: t, rules: lhs, rhs)
    }
}