import Foundation

typealias Path = [String]

extension Path {

    init(_ path: [CodingKey]) {
        self = path.map { $0.stringValue }
    }

    var pretty: String {
        self.joined(separator: ".")
    }

    func split() -> (String, Path) {
        let head = self.first!
        let tail = Array(self.suffix(from: 1))
        return (head, tail)
    }
}

public protocol Verifiable: Decodable {
	init()
}

extension Verifiable {
	
	private var props: Mirror.Children {
		return Mirror(reflecting: self).children
	}

	var children: [(String, Verifiable)] {
		props.compactMap { prop in
			guard let label = prop.label, 
				let child = prop.value as? Verifiable else {
				return nil
			}
			return (label, child)
		}
	}

	var constraints: [(String, Constraint)] {
		props.compactMap { prop in
			guard let label = prop.label?.split(separator: "_").last, 
				let constraint = prop.value as? Constraint else {
				return nil
			}
			return (String(label), constraint)
		}
	}

	func child(for name: String) -> Verifiable? {
		props.first { $0.label == name }
			.flatMap { $0.value as? Verifiable }
	}

	func constraint(for name: String) -> Constraint? {
		props.first { $0.label == "_\(name)" }
			.flatMap { $0.value as? Constraint }
	}

}

extension Verifiable {
	
    func prepareForVerification(context: VerificationContext, path: Path) {
        children.forEach { (name, child) in
			let path = path + [name]
			child.prepareForVerification(context: context.rebase(path: path), path: path) 
		}
        constraints.forEach { (name, constraint) in
			constraint.context = context.rebase(path: path + [name])
        }
    }
	
	func getRuleFor<V>(path: Path) -> Rule<V>? where V: Decodable {
		guard !path.isEmpty else {
			return nil
		}
		if path.count == 1 {
			return getRuleFor(key: path.last!)
		} else {
			let (head, tail) = path.split()
			return child(for: head)?.getRuleFor(path: tail)
		}
	}
	
	func getRuleFor<V>(key: String) -> Rule<V>? where V: Decodable {
		return constraint(for: key)
			.flatMap { $0.getCastRule() }
	}
}

public func verify(_ verifiables: Verifiable..., block: () -> Void) throws {
    let verification = Verification()
    let context = VerificationContext(instance: nil, path: [], strict: false, verification: verification)
    verifiables.forEach {
		$0.prepareForVerification(context: context, path: [])
	}
    block()
    if verification.failing {
        throw VerificationError.rulesBroken(rules: verification.failures)
    }
}

public func verifyStrict(_ verifiables: Verifiable..., block: () -> Void) throws {
    let verification = Verification()
    let context = VerificationContext(instance: nil, path: [], strict: true, verification: verification)
    verifiables.forEach {
		$0.prepareForVerification(context: context, path: [])
	}
    block()
    if verification.failing {
        throw VerificationError.rulesBroken(rules: verification.failures)
    }
}