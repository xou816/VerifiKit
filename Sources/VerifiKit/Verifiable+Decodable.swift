import Foundation

extension CodingUserInfoKey {
    static let verificationContext = CodingUserInfoKey(rawValue: "verificationContext")!
}

public protocol CompatibleDecoder: class {
    var userInfo: [CodingUserInfoKey : Any] { get set }
    func decode<T>(_ type: T.Type, from data: Data) throws -> T where T : Decodable
}

extension CompatibleDecoder {

    public func decode<T>(verify type: T.Type, from data: Data) throws -> T where T: Verifiable {
        let verification = Verification()
        self.userInfo[.verificationContext] = VerificationContext(instance: T(), path: [], strict: false, verification: verification)
        let result = try self.decode(type, from: data)
        if verification.failing {
            throw VerificationError.rulesBroken(rules: verification.failures)
        }
        return result
    }
    
    public func decode<T>(verifyStrict type: T.Type, from data: Data) throws -> T where T: Verifiable {
        let verification = Verification()
        self.userInfo[.verificationContext] = VerificationContext(instance: T(), path: [], strict: true, verification: verification)
        let result = try self.decode(type, from: data)
        if verification.failing {
            throw VerificationError.rulesBroken(rules: verification.failures)
        }
        return result
    }
}

extension Decoder {

    func getVerificationContext() throws -> VerificationContext {
        guard let context = userInfo[.verificationContext] as? VerificationContext else {
            throw VerificationError.contextError
        }
        return context.rebase(path: Path(codingPath))
    }

    func decodeConstrained<T>(_ type: T.Type, context: VerificationContext) throws -> (Rule<T>, T) where T: Decodable {
        let path = context.path
        guard let rule: Rule<T> = context.instance?.getRuleFor(path: path) else {
            throw VerificationError.contextError
        }
        let value = try singleValueContainer().decode(type)
        return (rule, value)
    }
}

extension JSONDecoder: CompatibleDecoder {}
extension PropertyListDecoder: CompatibleDecoder {}