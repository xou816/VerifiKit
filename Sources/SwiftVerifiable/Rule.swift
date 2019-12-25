protocol ComplianceTest {
    var pass: () -> Bool { get }
    var fail: (String) -> Bool { get }
}

struct SingleTest: ComplianceTest {
    let pass: () -> Bool
    let fail: (String) -> Bool
}

class TestProxy: ComplianceTest {

    let actualTest: ComplianceTest

    var failureReasons = [String]()
    var reason: String {
        failureReasons.joined(separator: "; ")
    }

    var pass: () -> Bool {{ true }}
    var fail: (String) -> Bool {{ [unowned self] reason in
        self.failureReasons.append(reason)
        return false
    }}

    init(wrap test: ComplianceTest) {
        actualTest = test
    }

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

struct Rule<T> {

    let test: (T, ComplianceTest) -> Bool
    
    init(_ test: @escaping (T, ComplianceTest) -> Bool) {
        self.test = test
    }
    
    init(predicate: @escaping (T) -> Bool) {
        self.test = { (arg, test) in
            predicate(arg) ? test.pass() : test.fail("Test failed")
        }
    }
    
    static func passing<T>() -> Rule<T> {
        return Rule { (_, test) in test.pass() } as! Rule<T>
    }
    
    static func failing<T>(reason: String) -> Rule<T> {
        return Rule { (_, test) in test.fail(reason) } as! Rule<T>
    }
}

extension Rule {

    static func not<T>(_ rule: Rule<T>) -> Rule<T> {
        return Rule<T> { (t, test) in
            let proxy = TestProxy(wrap: test)
            return proxy.notPass(value: t, rule)
        }
    }

}

func &<T>(_ lhs: Rule<T>, _ rhs: Rule<T>) -> Rule<T> {
    return Rule { (t, test) in
        let proxy = TestProxy(wrap: test)
        return proxy.allPass(value: t, lhs, rhs)
    }
}

func |<T>(_ lhs: Rule<T>, _ rhs: Rule<T>) -> Rule<T> {
    return Rule { (t, test) in
        let proxy = TestProxy(wrap: test)
        return proxy.anyPass(value: t, lhs, rhs)
    }
}