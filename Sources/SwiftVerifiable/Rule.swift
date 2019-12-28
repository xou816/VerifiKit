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