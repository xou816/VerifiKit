protocol Constraint: class {

    func getCastRule<T>() -> Rule<T>?

    var pass: () -> Bool { get }
    var fail: (String) -> Bool { get }
    var context: VerificationContext { get set }
}

extension Constraint {
    func runTest<T>(for value: T) -> Bool {
        let test = SingleTest(pass: self.pass, fail: self.fail)
        return getCastRule()?.test(value, test) ?? false
    }
}