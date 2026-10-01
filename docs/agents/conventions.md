# Conventions

Read before writing Swift. SwiftLint and SwiftFormat enforce the mechanical parts;
this file covers what they cannot.

## Files and comments

Every file starts with its own name as a single comment line, a blank line, then
imports. No Xcode boilerplate, no copyright, no author, no date:

```swift
// ProductViewModel.swift

import Foundation
```

**Comments explain why, never what.** A comment restating the code is deleted —
that was the whole of commit `a74a5cf`. `///` doc comments go on public API and on
tests whose purpose is not obvious from the name. Comments are hand-wrapped at a
natural break, which is why SwiftFormat's `wrapSingleLineComments` is off.

Where a decision is non-obvious, the comment says what it costs or what it
prevents:

```swift
// Must be inside the label: `.plain` hit-tests the label's own
// shape, so outside the Button the row's gaps ignore taps.
.contentShape(.rect)
```

`todo` is deliberately not a SwiftLint violation — a TODO is a note, not a defect.

## Access control

Explicit and minimal. `public` on the feature entry-point enum, routes, events,
domain models, view models, views and their initialisers. Everything reachable
only inside the module — repositories, session clients, Core Data storage,
response DTOs, small subviews — stays internal.

State is `public private(set) var`; dependencies are `private let`. Public structs
get their memberwise initialiser written out longhand, since the synthesised one
is internal.

## View models

Uniformly `@MainActor @Observable public final class`, with the state enum
declared directly above in the same file:

```swift
public enum ProductLoadingState {
    case loading, loaded, error(Error)
}

@MainActor
@Observable
public final class ProductViewModel {
    private let repository: ProductRepository
    private let emit: (ProductEvent) -> Void

    public private(set) var products: [Product] = []
    public private(set) var loadingState: ProductLoadingState = .loading
```

Two state shapes recur: `.loading / .loaded / .error` for lists, and
`.loading / .loaded(T) / .notFound / .error` for details. `emit` defaults to a
no-op so previews and tests need no navigation wiring.

## Views

`public struct X: View`, holding its view model in one of two ways depending on
who builds it:

- **Root list views** (`ProductView`, `UserView`) take theirs as
  `private let viewModel`. `MainApp` builds each one once and owns it in
  `@State` (commit `265c051`), so rebuilding it per render cannot restart its work.
- **Pushed screens** built by `Products.view` / `Users.view` (`ProductDetailView`,
  `UserProfileView`) hold theirs in `@State private var viewModel`, set from the
  initialiser with `_viewModel = State(wrappedValue:)`. SwiftUI tracks an
  `@Observable` only when it is read through a property wrapper; a plain `let`
  registers no observation, so the screen never redraws after `state` leaves
  `.loading` (commit `b9fba80`).

Beyond those two cases, `@State` in a feature view is for genuinely view-local UI
state only.

Body is a `Group { switch viewModel.state { ... } }` with `.task { await ... }`
attached. Subviews are `private var x: some View` when they take no parameters and
`private func x(_:) -> some View` when they do.

Tappable rows are a `Button` with `.buttonStyle(.plain)`, and `.contentShape(.rect)`
goes **inside** the label — outside it, a plain button hit-tests only its opaque
subviews and the row's gaps ignore taps (commit `ebc22d4`).

Accessibility identifiers for UI tests are kebab-case. Suffix the id only where
one is needed to tell repeated elements apart —
`.accessibilityIdentifier("product-row-\(product.id)")` for a list row, but plain
`"seller-row"` where the screen has exactly one.

Styling is stock SwiftUI plus iOS 26 APIs — `.glassEffect(.regular.interactive(), in:)`,
`.backgroundExtensionEffect()`, `.tabBarMinimizeBehavior(.onScrollDown)`,
`ContentUnavailableView`, `LabeledContent`, `.foregroundStyle(.secondary)`.

## Concurrency

Swift 6 language mode, strict checking. Domain models and protocols are `Sendable`.
`@MainActor` goes on Presentation types only — Domain and Data never touch the main
actor.

MainActor-by-default (`SWIFT_DEFAULT_ACTOR_ISOLATION`) is set on the **App target
only**, and `Project.swift` explains why: applied project-wide it lands on domain
types, storage and repositories, every one of which would then need `nonisolated`
to opt back out.

**No `@unchecked Sendable`**, in shipping code or tests. It asserts safety the
compiler cannot check, and a wrong assertion is a data race Swift 6 no longer
catches. SwiftLint's `no_unchecked_sendable` custom rule makes it an error. Make
the conformance provable instead:

- Store something `Sendable` rather than the non-`Sendable` object.
  `ProductCacheTimestamp` keeps a suite name and resolves `UserDefaults` per call.
- Guard mutable state in a `Mutex` from `Synchronization`, as the test doubles in
  `ProductCachePolicyTests.swift` do. An actor is the alternative, but it cannot
  satisfy a synchronous protocol requirement.
- Check the SDK before assuming a type is unmarked: `NSPersistentContainer` is
  `NS_SWIFT_SENDABLE`, so `StorageProvider` conforms plainly.

Prefer `Date.ISO8601FormatStyle` over `ISO8601DateFormatter`, which is a
non-Sendable class.

## Style the formatter locks in

Several SwiftFormat rules are disabled on purpose. Match the resulting style:

- **`case let .detail(id)`**, pattern-let hoisted left — `hoistPatternLet` is off.
- **`try` and `await` on the argument that can fail**, not lifted to the front of
  the statement: `storageProvider: try StorageProvider(...)` shows *which*
  argument throws. `hoistTry` and `hoistAwait` are off.
- **Explicit types in initialisers** even when inferable — `redundantType` is off,
  because the type documents intent there.
- Single-expression switch arms use the implicit return:
  `case .list: "/products"`.

Mechanical settings: 4-space indent, 140 columns, `before-first` wrapping for
arguments and collections, trailing commas always, `self` removed where implicit,
attributes on the previous line for functions and types but the same line for
stored properties.

## Errors

Typed throws in the data layer: `async throws(StorageError)`,
`async throws(APIError)`. Never force unwrap — trap with `fatalError` naming what
broke, as `AppContainer.live()` does. Silencing the linter instead is not an option.

## Mapping

DTO and entity to domain via `toDomain()`, with an array-level extension where a
collection is mapped:

```swift
extension [ProductResponse] {
    func toDomain() -> [Product] {
        map { $0.toDomain() }
    }
}
```
