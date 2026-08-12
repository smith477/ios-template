# Architecture

Read before adding or changing a module, feature, or route.

## Layers

From the top of `Project.swift`, which is where this rule is enforced:

>     App       may import every feature and platform module. It is the only
>               place where features are wired together.
>     Feature   may import platform modules and APIClient.
>               A feature may never import another feature — that is the one
>               boundary worth a target, because it is what keeps a feature
>               copyable into another project.
>     Platform  imports nothing from this project. It knows no feature.

Domain, Data and Presentation are **folders inside a feature, not targets**. Split
a feature into layer targets only once it is large enough to earn them; until then
the ceremony costs more than it returns.

`tuist inspect dependencies --only implicit` is what catches a violation. CI runs
it under the older `tuist inspect implicit-imports` spelling, which Tuist 4.203.3
deprecates but still accepts.

## What goes in Platform

From `Modules/Platform/Identity/Sources/User.swift`:

> Admission rule for Platform modules: a type moves here once a *second*
> feature needs it, never in anticipation. Value types only.

Existing Platform modules: `Identity` (the `User` value type), `AppKit`
(`DateProvider`), `Persistence` (the Core Data stack). There is deliberately no
design-system module — shared UI would become one on the same second-consumer
rule, not before.

## Feature anatomy

`Modules/Features/Products/` is the reference implementation. `Users/` is the same
shape, deliberately simpler — copy Products when the new feature needs caching or
a detail screen, Users when it does not.

Two files sit at the module root:

**`<Feature>.swift`** — a `public enum` namespace that is the feature's *only*
public factory. The repository, storage and client stay internal:

```swift
public enum Products {
    @MainActor
    public static func viewModel(
        _ dependencies: some ProductsDependencies,
        emit: @escaping (ProductEvent) -> Void
    ) -> ProductViewModel { ... }

    @MainActor
    public static func view(
        _ route: ProductRoute,
        _ dependencies: some ProductsDependencies,
        emit: @escaping (ProductEvent) -> Void
    ) -> some View { ... }

    private static func repository(_ dependencies: some ProductsDependencies) -> ProductRepository { ... }
}
```

`emit` is required on these factories, unlike on the view-model initialisers where
it defaults to a no-op: a composed screen that drops its events is a bug, while a
preview or test that does is fine.

**`<Feature>Dependencies.swift`** — a protocol declaring what the feature needs
from the app. `AppContainer` conforms by empty extension
(`extension AppContainer: ProductsDependencies {}`), so adding a platform
dependency later changes the protocol and the container, not every call site.

Then the three folders:

- **`Domain/`** — value types, the repository *protocol*, `CachePolicy`. No
  SwiftUI, no UIKit, no Core Data.
- **`Data/`** — `<X>ApiClient` protocol and its `<X>APISessionClient` impl,
  `<X>Endpoint: Endpoint`, `Decodable` response DTOs with `toDomain()`,
  `<X>Entity: NSManagedObject`, `<X>Storage` protocol and its Core Data impl, and
  `<X>DataRepository` combining client and storage.
- **`Presentation/`** — `<X>View` / `<X>ViewModel` pairs, `<X>Route`, `<X>Event`.

## Routing

**Events describe what happened, not what should happen next.** From
`ProductEvent.swift`:

> Cases describe what happened, not what should happen next: `sellerTapped`
> rather than `showUser`. The feature reports; the app decides where it leads.

A view model takes `emit: (Event) -> Void` and calls it. It has no router, no
navigation state, and no knowledge of any other feature.

**`AppRouter`** (`App/Router/AppRouter.swift`) is `@MainActor @Observable` and owns
one stack per tab, as typed arrays rather than `NavigationPath` — which erases its
contents and so cannot be asserted against beyond its depth. Three primitives:

- `push(_:onto:)` — appends, ignoring a repeat of whatever is already on top so a
  double tap does not stack the same screen twice.
- `clearStack(_:)` — pops a tab to its root without changing the selected tab.
- `crossTo(_:in:)` — selects the tab first, then **replaces** its stack, discarding
  any flow in progress there. Safe only while that stack holds no unsaved input.
  Routing to the already-selected tab pushes instead. For destinations the user
  asked for outright, such as a deep link.

Choosing between them: pushing a screen from another feature onto the *current*
stack keeps Back returning where the user came from and leaves the other tab as
they left it. That is why a product's seller pushes onto the Products stack rather
than crossing to Users — see `AppRouter+Products.swift`.

**Event-to-navigation mapping** lives in one file per feature,
`App/Router/AppRouter+<Feature>.swift`. That file is the one place cross-feature
coupling is allowed, and it imports both features to do it.

**`AnyRoute`** is the cross-feature sum type. It lives in App because it names
every feature, and only the app may. Both `NavigationStack`s register every
feature's destinations, through the private `navigationDestinations` extension in
`TemplateApp.swift`, because either stack can show either feature's screens.

**Deep links** (`App/Router/DeepLink.swift`): `template://<host>/<id>`, host names
the tab, one optional positive-integer path component names the screen. Parsing is
strict — unknown host, unparsable or non-positive id, or more than one path
component all return `nil` rather than degrading to the tab root, because a link
that half-works lands the user somewhere they did not ask for. `.onOpenURL` is
attached outside the `TabView` so a link naming an unselected tab still works.

## Data layer

The repository protocol lives in Domain and is `Sendable`; `<X>DataRepository` in
Data implements it over an API client and a storage type, both of which are
protocols with Core Data and URLSession implementations behind them.

**Caching is a repository concern.** `CachePolicy` (in
`Domain/ProductRepository.swift`, alongside the protocol) is `.cacheFirst(maxAge:)`
or `.reload`, defaulting to an hour via a protocol extension; pull-to-refresh
passes `.reload`. A failed refresh falls back to the cache and only rethrows when
the cache is empty, so a network blip does not empty the screen. Freshness is a
stored timestamp (`ProductCacheTimestamp`, in `UserDefaults`) compared against an
injected `DateProvider` — the timestamp is real, the clock is fakeable.

`UserDataRepository` is deliberately simpler: cache-if-non-empty, no policy. The
two features are at different maturity levels on purpose.

**Errors are typed throws** through the data layer:
`func getAll() async throws(StorageError) -> [Product]`,
`func fetchProducts() async throws(APIError) -> [Product]`.

**Core Data** lives in `Platform/Persistence`. The `.xcdatamodeld` ships in that
module's resource bundle, so the model is loaded through
`StorageProvider.modelBundle` (`.module`) — `Bundle.main` will not find it, and a
project that gets this wrong crashes at launch. `StorageProvider.inMemory(...)` is
the test factory. Model name is `ios_template`.

**Networking** is the external `APIClient` package: an actor with
`send<T: Decodable & Sendable>(_ endpoint: Endpoint) async throws(APIError) -> T`.
Features declare endpoints as enums conforming to `Endpoint`.

## Dependency injection

`AppContainer` (`App/AppContainer.swift`) is a plain `final class`, explicitly not
a singleton, holding the `StorageProvider` and `APIClient`. It conforms to each
feature's dependencies protocol by empty extension. `AppContainer.live()` traps
with `fatalError` naming what broke rather than force unwrapping.

Lower-level seams use default-argument injection instead:
`dateProvider: DateProvider = SystemDateProvider()`,
`emit: @escaping (Event) -> Void = { _ in }`.

## Adding a feature

Worked example, adding `Orders`:

1. Create `Modules/Features/Orders/Sources/{Domain,Data,Presentation}/` and
   `Modules/Features/Orders/Tests/`. Copy a `Tests/.swiftlint.yml` from an
   existing feature — a new test directory needs one.
2. In `Project.swift`, add `feature("Orders", dependencies: [...])` and
   `featureTests("Orders", dependencies: [...])` to `targets`. Use the existing
   `feature(...)` helper; do not hand-write a `.target(...)`.
3. Add `.target(name: "Orders")` to the App target's dependencies, and to
   `AppTests` if app-level tests touch it.
4. Add `"OrdersTests"` to the `App` scheme's `testAction`, and a
   `testScheme("OrdersTests")` alongside the others.
5. Write `Orders.swift` (the entry-point enum), `OrdersDependencies.swift`,
   `OrderRoute`, `OrderEvent`, and the Domain/Data/Presentation types.
6. Wire it into `App/`:
   - `case order(OrderRoute)` in `AnyRoute` (`App/Router/AppRouter.swift`).
   - `import Orders` in `AppRouter.swift` and `TemplateApp.swift`.
   - `App/Router/AppRouter+Orders.swift` with `handle(_ event: OrderEvent)`.
   - The `case` in `navigationDestinations` in `TemplateApp.swift`.
   - `extension AppContainer: OrdersDependencies {}` in `AppContainer.swift`.
   - A `DeepLink` host, if the feature is linkable.
7. `mise exec -- tuist generate`, then build.

**Does the feature get its own tab?** Steps 1–7 cover a feature reached by pushing
onto an existing stack — which is what a seller profile does today, and the cheaper
option. A feature that needs its *own* tab additionally requires, all in
`App/Router/AppRouter.swift` and `App/TemplateApp.swift`:

- `case orders` in `AppRouter.Tab`, and `var ordersStack: [AnyRoute] = []`.
- A branch in each of the three switches over `Tab` — `push(_:onto:)`,
  `clearStack(_:)` and `crossTo(_:in:)`. They are exhaustive, so the compiler will
  name every one you miss.
- In `TemplateApp`: an `@State` view model, its `State(wrappedValue:)` line in
  `init()`, and a `Tab(...)` holding a `NavigationStack(path: $router.ordersStack)`
  with `.navigationDestinations(container:router:)` attached.

Adding a tab is a product decision, not a mechanical consequence of adding a
feature. Confirm it before doing it.

A new Platform module is the same as steps 1–2, with `platform(...)` and
`platformTests(...)`, and it must not gain a dependency on any feature.
