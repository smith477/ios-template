// DeepLink.swift

import Foundation
import Products
import Users

/// A destination named by a URL from outside the app.
///
/// Parsing is separated from acting on the result: `init?(_:)` is a pure
/// function of the URL, so the link grammar can be tested without a router,
/// and `AppRouter.open(_:)` decides what a destination does to the stacks.
///
/// The grammar, rooted at the `template` scheme:
///
///     template://products          the Products tab
///     template://products/7        product 7
///     template://users             the Users tab
///     template://users/3           user 3
///
/// Unknown hosts, unparsable ids and extra path components are rejected rather
/// than approximated: a link that half-works lands the user somewhere they did
/// not ask for, which is worse than a link that visibly does nothing.
struct DeepLink: Hashable {
    /// The tab the link names, which is selected whether or not a route
    /// follows.
    let tab: AppRouter.Tab

    /// The screen to show in `tab`, or `nil` for a link naming only the tab,
    /// which lands on its root.
    let route: AnyRoute?

    init(tab: AppRouter.Tab, route: AnyRoute?) {
        self.tab = tab
        self.route = route
    }

    /// Parses `url`, or returns `nil` if it does not name a destination.
    ///
    /// - Parameter url: A URL the app was opened with.
    init?(_ url: URL) {
        guard url.scheme == "template" else { return nil }

        // Percent-decoded, `/`-separated and free of the empty components a
        // trailing slash leaves behind.
        let components = url.pathComponents.filter { $0 != "/" }

        // A second component would carry meaning this grammar does not define.
        guard components.count <= 1 else { return nil }

        // The id, parsed before the host is known because both sections carry
        // one. Absent for a link naming only a tab; a component that does not
        // hold a usable id fails the whole parse rather than degrading to the
        // tab root, which would be a different destination than the one asked
        // for. `Int.init` refuses `7x`, and ids are server-assigned positives,
        // so a negative is malformed rather than merely absent.
        let id: Int?
        if let component = components.first {
            guard let parsed = Int(component), parsed > 0 else { return nil }
            id = parsed
        } else {
            id = nil
        }

        // `template://products/7` puts `products` in the host, not the path.
        switch url.host() {
        case "products":
            self.init(tab: .products, route: id.map { .product(.detail(id: $0)) })
        case "users":
            self.init(tab: .users, route: id.map { .user(.profile(id: $0)) })
        default:
            return nil
        }
    }
}

extension AppRouter {
    /// Shows the destination `url` names, and reports whether it named one.
    ///
    /// A deep link is the case `crossTo(_:in:)` exists for: the user asked to
    /// be somewhere outright, so they arrive at that screen rather than on top
    /// of whatever the tab held, and the tab's previous stack is discarded
    /// along with any back path into screens this visit never passed through.
    ///
    /// - Parameter url: A URL the app was opened with.
    /// - Returns: `false` if `url` names no destination, leaving navigation
    ///   untouched.
    @discardableResult
    func open(_ url: URL) -> Bool {
        guard let link = DeepLink(url) else { return false }

        if let route = link.route {
            crossTo(route, in: link.tab)
        } else {
            // A bare tab link: select it and show its root, so that following
            // the same link twice is idempotent rather than leaving whatever
            // the first one pushed.
            selectedTab = link.tab
            clearStack(link.tab)
        }
        return true
    }
}
