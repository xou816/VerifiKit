import Foundation

struct VerificationContext {

    let instance: Verifiable?
    let path: Path
    let strict: Bool
    var verification: Verification

    static var empty: VerificationContext {
        VerificationContext(instance: nil, path: [], strict: false, verification: Verification())
    }

    func rebase(path: Path) -> VerificationContext {
        return VerificationContext(instance: instance, path: path, strict: strict, verification: verification)
    }
}

public struct Failure {
    public let path: String
    public let reason: String
}

class Verification {

    var failures = [Failure]()

    var failing: Bool {
        !failures.isEmpty
    }

    var passing: Bool {
        failures.isEmpty
    }
    
    init() {}

    func passOne() {}

    func failOne(path: Path, reason: String) {
        failures.append(Failure(path: path.pretty, reason: reason))
    }
}

public enum VerificationError: Error {
    case contextError
    case rulesBroken(rules: [Failure])
}
