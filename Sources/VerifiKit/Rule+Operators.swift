extension TestProxy {

    func allPass<T>(value: T, _ rules: Rule<T>...) -> Bool {
        let result = rules
            .reduce(true) { (result, rule) in result && rule.test(value, self) }
        return result ? actualTest.pass() : actualTest.fail(reason)
    }

    func anyPass<T>(value: T, _ rules: Rule<T>...) -> Bool {
        let result = rules
            .reduce(false) { (result, rule) in result || rule.test(value, self) }
        return result ? actualTest.pass() : actualTest.fail(reason)
    }

    func notPass<T>(value: T, _ rule: Rule<T>) -> Bool {
        let result = rule.test(value, self)
        return result ? actualTest.fail("Expected test not to pass") : actualTest.pass()
    }
}

extension Rule {

    public static func not<T>(_ rule: Rule<T>) -> Rule<T> {
        return Rule<T> { (t, test) in
            let proxy = TestProxy(wrap: test)
            return proxy.notPass(value: t, rule)
        }
    }

}

public func &<T>(_ lhs: Rule<T>, _ rhs: Rule<T>) -> Rule<T> {
    return Rule { (t, test) in
        let proxy = TestProxy(wrap: test)
        return proxy.allPass(value: t, lhs, rhs)
    }
}

public func |<T>(_ lhs: Rule<T>, _ rhs: Rule<T>) -> Rule<T> {
    return Rule { (t, test) in
        let proxy = TestProxy(wrap: test)
        return proxy.anyPass(value: t, lhs, rhs)
    }
}