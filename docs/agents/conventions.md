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

Comments follow the
[Swift API Design Guidelines](https://www.swift.org/documentation/api-design-guidelines/#write-doc-comment)
and the [Google Swift Style Guide](https://google.github.io/swift/#comments):

1. **Public API** gets a `///` summary: one sentence fragment ending in a period —
   a verb phrase for a method, a noun phrase for a type or property. Add
   `- Parameters:`, `- Returns:` and `- Throws:` only when the summary does not
   cover them.
2. **Internal and private declarations** get a doc comment only when the name and
   signature leave a real question.
3. **`//` in code** states a non-obvious *why* in one or two lines, never a *what*.
4. **No history or process.** No "used to", "was really", commit hashes, issue
   numbers, bug stories or decision narratives; those belong in `git log` and the
   PR.
5. **Tests** state the scenario in the function name. Add a comment only when the
   name cannot carry it.
6. **Length:** a summary plus about two lines. An explanation longer than that
   belongs in `docs/agents/`.

```swift
// `.plain` hit-tests the label's own shape, so outside the label the gaps ignore taps.
.contentShape(.rect)
```

Comments are hand-wrapped at a natural break, which is why SwiftFormat's
`wrapSingleLineComments` is off.

`todo` is deliberately not a SwiftLint violation — a TODO is a note, not a defect.

## File size and responsibility

A file holds one primary type, plus the small private helpers and extensions that
serve only that type. A view model's state enum sits beside it, and a view's
private subviews stay in the view's file.

Split a file when a second type in it has its own reason to change, or when a size
limit fires. Do not split a cohesive type into arbitrary pieces just to get under a
limit; extensions spread across files to dodge `type_body_length` are the
over-splitting the limits exist to prevent.

The limits live in `.swiftlint.yml`, warning / error:

| Rule | Sources | Tests |
|---|---|---|
| `file_length` (comment-only lines not counted) | 300 / 450 | 250 / 350 |
| `type_body_length` | 200 / 300 | 200 / 300 |
| `function_body_length` | 50 / 80 | 50 / 80 |

CI lints with `--strict`, so the warning value is the one that blocks. They are
defaults: a project that outgrows one changes it in the config.

When a type that does one job really is that big, keep it whole and disable the
limit with the reason on the line above, then say so in the PR:

```swift
@MainActor
@Observable
// One state machine; splitting it would scatter the transitions.
// swiftlint:disable:next type_body_length
public final class CheckoutViewModel {
```

The `disable:next` goes directly above the `struct`, `class` or `func` line,
*below* any attributes: the violation is reported on the keyword's line, so above
the attributes it silences nothing. For `file_length`, put
`// swiftlint:disable file_length` between the file-name line and the imports,
with the reason on the line above it. Never disable a limit without a reason.

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
  `ProductListRecord` keeps a suite name and resolves `UserDefaults` per call.
- Guard mutable state in a `Mutex` from `Synchronization`, as the test doubles in
  `Modules/Features/Products/Tests/Support/` do. An actor is the alternative, but
  it cannot satisfy a synchronous protocol requirement.
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

## Shared code

When the same job appears at more than one call site, write one generic API for it,
not a function per call site, and put it where every caller can reach it (Platform
once a second module needs it). Names the code already knows — the module, a type —
are derived (`#fileID`, `String(describing: Self.self)`), never retyped as string
literals.

## Logging

Every module logs through `Log` from `Platform/Diagnostics`, held by the type that
logs:

```swift
private static let log = Log()
```

Its category is the module's name, read from `#fileID`, and its subsystem is the
app's bundle ID: one Console filter catches the app, and the category narrows it to
a module. Nothing is written by hand, so a copied or renamed module needs no edit.

`Log.swift` is the only file that imports `os`; never use `Logger` directly.
SwiftLint's `log_through_diagnostics` custom rule makes either an error. `os`
applies privacy only where a message is written, so `Log` takes no message string.
Event text is a `StaticString` and values are `Int`s, both public; an error logs its
domain and code publicly and its description privately. Nothing a user or server
wrote reaches the log in the clear.

Pick the level by what the user experiences:

- **`error`** — a failure the user sees, or one no caller will log again.
- **`notice`** — a failure the app absorbed, such as a refresh served from the cache.
- **`debug`** — a routine decision: a cache hit, a fetch. Kept in memory only, so it
  costs nothing in production; Xcode's console shows it, Console.app only with
  *Include Debug Messages*.

Log a failure once, where it is handled. `StorageProvider.performBackground` logs
every Core Data failure, so storage types and repositories rethrow those without
logging them. A repository logs its network failures and cache decisions;
`ProductDataRepository` is the example.

Logging has no tests: the safety is in `Log`'s parameter types, and what a flow
logs is checked in Console.

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
