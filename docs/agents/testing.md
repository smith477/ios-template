# Testing

Read before writing or changing tests.

## Which framework

**Swift Testing** for all unit tests — `AppTests`, `ProductsTests`, `AppKitTests`,
`PersistenceTests`.
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

A module's tests live beside it and use `@testable`, so a module needs no public
surface for the sake of being tested. Tests that span modules — the container,
routing — belong to the App target instead.

So: `Modules/Features/Products/Tests/` for anything inside Products;
`AppTests/` for the container, routing, and deep links.

Every `Tests/` directory has a `.swiftlint.yml`:

```yaml
parent_config: ../.swiftlint.yml

disabled_rules:
  - force_unwrapping
  - force_cast
  - force_try

file_length:
  warning: 250
  error: 350
  ignore_comment_only_lines: true
```

A force unwrap in a test fails that test immediately and never ships. A new test
directory needs this file, or the root config's error-level force rules will fail
the lint job.

A nested rule block replaces the root's whole block rather than merging into it,
so `ignore_comment_only_lines` has to be restated or comment lines start counting.
`type_body_length` and `function_body_length` are left out and come from the root.

`Users` and `Identity` have no test targets yet. Adding one means a
`featureTests(...)` / `platformTests(...)` entry in `Project.swift`, a
`testScheme(...)`, and the bundle name in the `App` scheme's `testAction`.

## Test doubles

A test file covers one subject, and its suite is what the file is for. A double
that one file uses is a `private` type in that file:

```swift
/// Serves its products by id, answers 404 for any other.
private final class ByIdApiClient: ProductApiClient {
    private let count = Mutex(0)
    ...
}
```

When a second file needs the same double, fixture or factory, move it to a
`Support/` folder in the bundle's test directory (`Tests/Support/` in a module,
`AppTests/Support/` for the app) instead of copying it: one type per file, named
after the type, internal rather than `private`, and no `@Test` in any of them. A
double moves when a second file needs it, not in anticipation. The bundle's source
glob already covers the folder, so it needs no `Project.swift` change.

`Modules/Features/Products/Tests/Support/` is the example to copy:
`Product.fixture(id:title:)` in `Product+Fixture.swift`, the counting doubles,
`MovableDateProvider`, and `ProductStorageFactory.swift`, whose free
`makeStorage(dateProvider:)` returns storage over an in-memory store and a
`ProductListRecord(suiteName: UUID().uuidString)`, so neither the rows nor the
list record of one test reach the next.

Seams that already exist, to use rather than replace: `DateProvider` (inject
`MovableDateProvider` to age a cache without waiting), `ProductListRecord`
(injectable `UserDefaults` suite name), and the defaulted `emit` closure on view-model
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
mise exec -- tuist test App --no-selective-testing --device "iPhone 18 Pro"            # everything
mise exec -- tuist test ProductsTests --no-selective-testing --device "iPhone 18 Pro"  # one bundle
```

Bundles: `AppTests`, `AppUITests`, `ProductsTests`, `AppKitTests`,
`PersistenceTests`. Run the bundle covering what changed while iterating; run `App`
before handing work over.

`--device "iPhone 18 Pro"` is required. Without it `tuist test` picks whichever
simulator is booted, and a different screen geometry puts UI-test taps in the
wrong place. CI uses iPhone 17 Pro, the newest its Xcode 26 image ships.

A per-bundle `tuist test` can leave the generated project trimmed to that bundle,
with no app target, so the `App` scheme will not run in Xcode.
`mise exec -- tuist generate` restores it.

Run `mise exec -- tuist generate` first if `Project.swift` changed.

## The UI test that used to be skipped

`AppUITests/RoutingUITests.swift` was skipped behind
`appLoadsPastTheProductList = false`, recording a whole-app freeze once a screen
was pushed. The skip is gone and the test passes: the freeze was really a
pushed screen that never redrew.

A view must read an `@Observable` view model through a property wrapper for
SwiftUI to track it. `ProductDetailView` and `UserProfileView` held theirs in a
plain `let`, so no dependency was registered and neither view was invalidated
when `state` left `.loading` — the screen drew its `ProgressView` forever while
the push and the `.task` both ran normally. Both now use `@State`. The root
views were never affected, because `MainApp` holds their view models in
`@State` already.

Worth knowing when a UI test hangs on a screen that looks stuck: check that the
view actually observes its view model before suspecting the loading path. The
data layer was innocent here — `ProductDetailViewModel.load()` against the live
API and a real store finishes in 0.29s.
