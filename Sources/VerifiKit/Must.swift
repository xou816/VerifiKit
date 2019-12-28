@propertyWrapper
class Must<T>: Constraint, Decodable where T: Decodable {
    
    let rule: Rule<T>
    var context: VerificationContext = .empty

    var pass: () -> Bool {{ [unowned self] in
        self.context.verification.passOne()
        return self.context.verification.passing
    }}

    var fail: (String) -> Bool {{ [unowned self] reason in
        self.context.verification.failOne(path: self.context.path, reason: reason)
        return false
    }}
    
    init(_ rule: Rule<T>) {
        self.rule = rule
    }
    
    func getCastRule<U>() -> Rule<U>? {
        return rule as? Rule<U>
    }

    private var wrapped: T!
    var wrappedValue: T {
        get {
            wrapped
        }
        set(value) {
            if runTest(for: value) {
                wrapped = value
            }
        }
    }
    
    // MARK: - Decodable
    
    convenience required init(from decoder: Decoder) throws {
        let context = try decoder.getVerificationContext()
        let (rule, value) = try decoder.decodeConstrained(T.self, context: context)
        self.init(rule)
        self.context = context
        self.wrappedValue = value
    }
}