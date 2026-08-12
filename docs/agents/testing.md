# Testing

Read before writing or changing tests.

## Which framework

**Swift Testing** for all unit tests — `AppTests`, `ProductsTests`, `AppKitTests`.
`import Testing`, `struct` suites (not classes), `@Test` functions, `#expect`,
`try #require`, `Issue.record`, `@Test(arguments:)` for parameterised cases. Put
`@MainActor` on the suite struct when it touches view models or the router.

**XCTest** only for `AppUITests`, because XCUITest requires it.

**No snapshot testing**, and no snapshot dependency in the project. Adding one is
a decision to raise, not a default.

## Naming

Test functions are full sentences describing the scenario, with no `test` prefix
under Swift Testing:

```swift
func cacheFirstServesFromCacheWhileFresh()
func aSellerTapDoesNotDisturbTheUsersTab()
func aRejectedIdDoesNotDegradeToTheTabRoot()
```

SwiftLint's `identifier_name.min_length` is lowered to 2 for exactly this reason —
the root config says test names are long by design. XCUITest keeps the required
`test` prefix.

The suite type name need not match the file name: `RoutingTests.swift` holds
`struct AppRouterTests`, `ProductEventTests.swift` holds `struct FeatureEventTests`.

## Where tests live

From `Project.swift`:

> A module's tests live beside it and use `@testable`, so a module needs no public
> surface for the sake of being tested. Tests that span modules — the container,
> routing — belong to the App target instead.

So: `Modules/Features/Products/Tests/` for anything inside Products;
`AppTests/` for the container, routing, and deep links.

Every `Tests/` directory has a `.swiftlint.yml`:

```yaml
parent_config: ../.swiftlint.yml

disabled_rules:
  - force_unwrapping
  - force_cast
  - force_try
```

A force unwrap in a test fails that test immediately and never ships. A new test
directory needs this file, or the root config's error-level force rules will fail
the lint job.

`Users`, `Identity` and `Persistence` have no test targets yet. Adding one means
a `featureTests(...)` / `platformTests(...)` entry in `Project.swift`, a
`testScheme(...)`, and the bundle name in the `App` scheme's `testAction`.

## Test doubles

Doubles are `private` types declared in the same file as the test that uses them,
not shared fixtures:

```swift
/// Counts calls so a test can tell a cache hit from a refetch.
private final class CountingApiClient: ProductApiClient, @unchecked Sendable {
    private(set) var fetchCount = 0
    ...
}
```

Shared *factories* are the exception, and go in a file with no `@Test` in it —
`Modules/Features/Products/Tests/ProductStorageFactory.swift` exposes a free
`makeStorage(dateProvider:)` returning storage over an in-memory store and a
`UserDefaults(suiteName: UUID().uuidString)`, so neither the rows nor the cache
timestamp of one test reach the next.

Seams that already exist, to use rather than replace: `DateProvider` (inject
`MovableDateProvider` to age a cache without waiting), `ProductCacheTimestamp`
(injectable `UserDefaults`), and the defaulted `emit` closure on view-model
initialisers.

## Imports

Regular imports alphabetised, then a blank line, then `@testable` last:

```swift
import APIClient
import AppKit
import Foundation
import Testing

@testable import Products
```

SwiftFormat's `sortImports` is disabled specifically to preserve this ordering —
do not "fix" it.

## Running them

```bash
mise exec -- tuist test App --device "iPhone 17 Pro"            # everything
mise exec -- tuist test ProductsTests --device "iPhone 17 Pro"  # one bundle
```

Bundles: `AppTests`, `AppUITests`, `ProductsTests`, `AppKitTests`. Run the bundle
covering what changed while iterating; run `App` before handing work over.

`--device "iPhone 17 Pro"` is required. Without it `tuist test` picks whichever
simulator is booted, and a different screen geometry puts UI-test taps in the
wrong place.

Run `mise exec -- tuist generate` first if `Project.swift` changed.

## The skipped UI test

`AppUITests/RoutingUITests.swift` gates on
`private static let appLoadsPastTheProductList = false` and `XCTSkipUnless`. Its
doc comment records an open defect: once a screen is pushed the app freezes, and
it reproduces on a baseline build, so it predates the surrounding work.

A green suite therefore does not cover that flow. Do not flip the flag or delete
the skip to make things pass — fixing it means fixing the freeze, and the comment
is the record of what is known.
