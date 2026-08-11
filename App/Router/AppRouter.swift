// AppRouter.swift

import Products
import SwiftUI
import Users

/// Owns every navigation stack in the app and is the only type that pushes
/// onto them.
///
/// Features do not navigate. A feature emits an event describing what the user
/// did, and a `handle(_:)` overload maps that event to a stack change. Each
/// feature's mapping lives in `AppRouter+<Feature>.swift`; read those to find
/// out where a tap leads.
///
/// Features cannot reach this type: they are separate targets that do not
/// depend on `App`, so no feature can name `AppRouter`, `AnyRoute`, or another
/// feature's routes.
///
/// Two kinds of navigation do not pass through `handle(_:)`: popping (a back
/// swipe or Back button) and tab selection, both of which SwiftUI writes
/// straight through the bindings. `handle(_:)` is therefore an index of
/// programmatic destinations, not a record of every navigation change.
///
/// - Important: Each event maps to exactly one destination. Supporting a
///   context where the same event resolves differently — an iPad split view
///   filling a detail pane rather than pushing — requires passing that context
///   to `handle(_:)`, not returning routing decisions to the features.
@MainActor
@Observable
final class AppRouter {
    enum Tab: Hashable {
        case products
        case users
    }

    var selectedTab: Tab = .products

    /// The screens stacked above each tab's root, bound to that tab's
    /// `NavigationStack`.
    ///
    /// One stack per tab, so each tab keeps its own depth across tab switches.
    /// A stack may hold routes from any feature — opening a seller from
    /// Products pushes a `UserRoute`.
    ///
    /// Typed arrays rather than `NavigationPath`: `NavigationPath` erases its
    /// contents, which makes the stacks impossible to assert against beyond
    /// their depth.
    var productsStack: [AnyRoute] = []
    var usersStack: [AnyRoute] = []

    /// Pushes `route` onto `tab`'s stack.
    ///
    /// Does nothing if `route` is already the top of that stack, so a button
    /// tapped twice before the push renders does not stack the same screen
    /// twice. A route may still appear more than once in a stack with other
    /// screens between.
    ///
    /// - Parameters:
    ///   - route: The screen to show.
    ///   - tab: The tab whose stack to push onto. Does not change the selected
    ///     tab; use `crossTo(_:in:)` for that.
    func push(_ route: AnyRoute, onto tab: Tab) {
        switch tab {
        case .products:
            guard productsStack.last != route else { return }
            productsStack.append(route)
        case .users:
            guard usersStack.last != route else { return }
            usersStack.append(route)
        }
    }

    /// Pops `tab` back to its root.
    ///
    /// - Parameter tab: The tab whose stack to empty. Does not change the
    ///   selected tab.
    func clearStack(_ tab: Tab) {
        switch tab {
        case .products: productsStack = []
        case .users: usersStack = []
        }
    }

    /// Shows `route` in `tab`, selecting that tab first.
    ///
    /// For destinations the user asked to go to outright — a deep link, a
    /// notification tap — not for a screen that belongs to the one on display.
    /// Pushing a related screen onto the current stack, as a product's seller
    /// does, keeps Back pointing at where the user came from; crossing tabs
    /// would strand them in a tab with no way back. `open(_:)` is the caller;
    /// no feature event maps here, and one that did would be worth questioning.
    ///
    /// When `tab` is not already selected, `route` **replaces** its stack: the
    /// user arrives on the screen they asked for rather than on top of screens
    /// they left behind. Any in-progress flow in that tab is discarded, which
    /// is safe only while its stack holds no unsaved input.
    ///
    /// When `tab` is already selected, `route` is pushed instead, preserving
    /// the back stack the user can see.
    ///
    /// - Parameters:
    ///   - route: The screen to show.
    ///   - tab: The tab that owns `route`.
    func crossTo(_ route: AnyRoute, in tab: Tab) {
        guard tab != selectedTab else {
            push(route, onto: tab)
            return
        }

        selectedTab = tab
        switch tab {
        case .products: productsStack = [route]
        case .users: usersStack = [route]
        }
    }
}

/// Any feature's route, so that one stack can hold screens from several
/// features.
///
/// Lives in the app because it names every feature, and only the app is
/// allowed to. Adding a feature means adding a case here.
///
/// - Note: A case per feature makes this a shared edit point as the app grows.
///   If it becomes a source of conflicts, a type-erased box over a common
///   `Route` protocol removes the need to modify this type per feature.
enum AnyRoute: Hashable, Codable {
    case product(ProductRoute)
    case user(UserRoute)
}
