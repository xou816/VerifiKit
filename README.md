# VerifiKit [![Build Status](https://travis-ci.org/xou816/VerifiKit.svg?branch=master)](https://travis-ci.org/xou816/VerifiKit)

Declarative decodable object validation.

```swift
struct Client: Verifiable {

    @Should(.notBeEmptyString)
    var name: String?
    
    init() {}
}

struct Basket: Verifiable {

    @Must(.bePositiveInteger)
    var amount: Int = 1
    
    var client = Client()
    
    init() {}
}
```

## What it is

This library allows you to perform some simple validation on `Decodable` objects as you decode them.

It is only suitable for simple, independant assertions, **not** for complex business rules.


## Getting started

Implement the `Verifiable` protocol on your `Decodable` object. Its only requirement is an empty initializer.

```swift
struct Client: Verifiable {

    var name: String = "Name"
    
    init() {}
}
```

Then decode it from JSON using `decode(verify:from:)`:

```swift
let clientJson = #"{"name": "Toto"}"#.data(using: .utf8)!
let client = try? JSONDecoder().decode(verify: Client.self, from: clientJson)
```

If it works so far, you can start adding constraints ;)

## Property wrappers

`Must` and `Should` are property wrappers used to add validation rules to properties.

### `Should`

Wrapped fields marked with `@Should(rule)` are optionals. They cannot contain values that do not abide by the associated rule. 

Attempts to set an invalid value will set `nil` instead.

Therefore, with `if let` and similar constructs, you are assured to work with verified values.

### `Must`

Wraped fields marked with `@Must(rule)` are implictly unwrapped, allowing you to directly work with values.

Attempts to set an invalid value will fail silently.

Unlike with `Should`, decoding an invalid value will throw a `VerificationError`. 

## Validation rules

### Creating and combining rules

A rule is a simple closure:

```swift
let bePositiveInteger: Rule<Int> = Rule { (int, test) in
    int >= 0 ? test.pass() : test.fail("Expected positive integer")
}
```

Rules can be combined:

```swift
@Must(.beEmptyString | .beOfLength(3))
```

Or negated (in that case, the failure reason will be less explicit):

```swift
@Must(.not(.beEmptyString)) // use .notBeEmptyString instead
```

### Built-in rules

More may be added in the future.

Rules on integers:
- `bePositiveInteger`

Rules on strings:
- `notBeEmptyString`
- `notBeBlankString` (whitespace is blank space)
- `beEmptyString`
- `beBlankString`
- `beOfLength(Int)`
- `matchRegex(String)`

### Custom rules

To benefit from a nice, short syntax similar to that of the default set of rules, you should either:
- make your rules global functions
- make a static extension to `Rule`

## Verification

### For encoded objects

The library adds an extension to `JSONDecoder` which sets a context in `userInfo`.

The following methods are added:
* `decode(verify:from)` to decode a verifiable object
* `decode(verifyStrict:from)` to decode and throw errors with `Should` as well

### For assignements

It is possible to verify assignments in a block, using `verify` and `verifyStrict` (both `Should` and `Must` will throw with the latter):

```swift
try verify(myObject, myOtherObject) {
    myObject.validatedField = "invalid value"
    myOtherObject.validatedField = "some value"
}
```

This is needed because computed properties cannot throw.

### Error handling

A `VerificationError.rulesBroken` is thrown when an invalid assignement is attempted.

Its associated values `rules` is a list of `Failure`s (stuct with a reason string and a path to the error).