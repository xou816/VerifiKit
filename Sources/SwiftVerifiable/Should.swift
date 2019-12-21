@propertyWrapper
class Should<T>: Constraint, Decodable where T: Decodable {
    
    let rule: Rule<T>

    var context: VerificationContext = .empty

    var pass: () -> Bool {{
        self.context.verification.passOne()
        return self.context.verification.passing
    }}

    var fail: (String) -> Bool {{ reason in
        if self.context.strict {
            self.context.verification.failOne(path: self.context.path, reason: reason)
        } else {
            self.context.verification.passOne()
        }
        return false
    }}
    
    init(_ rule: Rule<T>) {
        self.rule = rule
    }
    
    func getCastRule<U>() -> Rule<U>? {
        return rule as? Rule<U>
    }

    private var wrapped: T? = nil
    var wrappedValue: T? {
        get {
            wrapped
        }
        set(value) {
            if let value = value, runTest(for: value) {
                wrapped = value
            } else {
                wrapped = nil
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

