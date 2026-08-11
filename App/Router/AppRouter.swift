// AppRouter.swift

import Products
import SwiftUI
import Users

/// Owns every navigation stack and is the only type that pushes onto them.
///
/// Features do not navigate: a feature emits an event, and a `handle(_:)`
/// overload in `AppRouter+<Feature>.swift` maps it to a stack change.
@MainActor
@Observable
final class AppRouter {
    enum Tab: Hashable {
        case products
        case users
    }

    var selectedTab: Tab = .products

    /// One stack per tab, so each keeps its own depth across tab switches. A
    /// stack may hold routes from any feature.
    ///
    /// Typed arrays rather than `NavigationPath`, which erases its contents and
    /// so cannot be asserted against beyond its depth.
    var productsStack: [AnyRoute] = []
    var usersStack: [AnyRoute] = []

    /// Pushes `route` onto `tab`'s stack, ignoring a repeat of whatever is
    /// already on top so a double tap does not stack the same screen twice.
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

    /// Pops `tab` back to its root without changing the selected tab.
    func clearStack(_ tab: Tab) {
        switch tab {
        case .products: productsStack = []
        case .users: usersStack = []
        }
    }

    /// Shows `route` in `tab`, selecting that tab first. For destinations the
    /// user asked for outright, such as a deep link.
    ///
    /// Crossing into an unselected tab **replaces** its stack, discarding any
    /// flow in progress there — safe only while that stack holds no unsaved
    /// input. Routing to the selected tab pushes instead.
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

/// Any feature's route, so one stack can hold screens from several features.
///
/// Lives in the app because it names every feature, and only the app may.
enum AnyRoute: Hashable, Codable {
    case product(ProductRoute)
    case user(UserRoute)
}
