---
description: "Writing Swift tests using Swift Testing framework: @Test, @Suite, #expect, #require, and focused runs"
---

# Swift Testing Framework

Always use Swift Testing (not XCTest) for new unit tests.

## Basic structure

```swift
import Testing

@Suite("UserAuthentication")
struct AuthTests {

    @Test("login succeeds with valid credentials")
    func loginSuccess() async throws {
        let auth = AuthService()
        let result = try await auth.login(user: "test", password: "correct")
        #expect(result.isAuthenticated)
    }

    @Test("login fails with wrong password")
    func loginFailure() async throws {
        let auth = AuthService()
        await #expect(throws: AuthError.invalidCredentials) {
            try await auth.login(user: "test", password: "wrong")
        }
    }
}
```

## Key macros

| Macro | Use for |
|-------|---------|
| `#expect(condition)` | Assert a condition (non-throwing) |
| `#expect(throws: ErrorType)` | Assert an error is thrown |
| `#require(optional)` | Unwrap optional or fail test |
| `#require(throws:)` | Assert throw and capture error |

```swift
// Unwrap optional — fails test if nil
let value = try #require(someOptional)

// Capture thrown error for inspection
let error = try #require(throws: MyError.self) {
    try functionThatThrows()
}
#expect(error.code == 404)
```

## Parameterised tests

```swift
@Test("validates email", arguments: [
    ("valid@email.com", true),
    ("notanemail", false),
    ("@missing.com", false),
])
func emailValidation(email: String, expected: Bool) {
    #expect(validateEmail(email) == expected)
}
```

## Async and actor isolation

```swift
@Test
func asyncOperation() async {
    let result = await someAsyncFunction()
    #expect(result != nil)
}

@Test
@MainActor
func mainActorTest() {
    // runs on MainActor
}
```

## Running focused tests via xcodebuild

```bash
# Single test method
xcodebuild test \
  -project MyApp.xcodeproj \
  -scheme MyApp \
  -destination "platform=macOS" \
  -only-testing:MyAppTests/AuthTests/loginSuccess

# Whole suite
xcodebuild test \
  -project MyApp.xcodeproj \
  -scheme MyApp \
  -destination "platform=macOS" \
  -only-testing:MyAppTests/AuthTests
```

## Dependency injection in tests

Use whichever DI approach the project already follows — initialiser injection, an `@Environment` value, a protocol witness, or a DI container like Swinject or Factory. The Swift Testing framework doesn't care; swap the production implementation for a test double at the seam the project's architecture provides.

```swift
// Initialiser injection (plainest seam)
let sut = LoginViewModel(auth: MockAuthService())

// Container-based (e.g. Swinject) — register a mock for the suite
container.register(AuthService.self) { _ in MockAuthService() }
let sut = container.resolve(AuthService.self)!
```

If the project mandates a specific DI pattern, that belongs in the project's conventions skill (for example, `ios-app-template-conventions`) — not this generic guide.
