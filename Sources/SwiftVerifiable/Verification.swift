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

struct Failure {
    let path: Path
    let reason: String
}

class Verification {

    enum Result {
        case pass
        case fail(Failure)
    }


    let uuid = UUID().uuidString
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
        failures.append(Failure(path: path, reason: reason))
    }
}

enum VerificationError: Error {
    case contextError
    case rulesBroken(rules: [Failure])
}
