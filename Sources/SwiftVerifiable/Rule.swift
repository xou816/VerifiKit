struct ComplianceTest {
    let pass: () -> Bool
    let fail: (String) -> Bool
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