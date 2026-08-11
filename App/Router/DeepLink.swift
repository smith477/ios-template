// DeepLink.swift

import Foundation
import Products
import Users

/// A destination named by a URL from outside the app.
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
/// not ask for, which is worse than one that visibly does nothing.
struct DeepLink: Hashable {
    let tab: AppRouter.Tab

    /// The screen to show in `tab`, or `nil` for a link naming only the tab.
    let route: AnyRoute?

    init(tab: AppRouter.Tab, route: AnyRoute?) {
        self.tab = tab
        self.route = route
    }

    /// Parses `url`, or returns `nil` if it does not name a destination.
    init?(_ url: URL) {
        guard url.scheme == "template" else { return nil }

        let components = url.pathComponents.filter { $0 != "/" }
        guard components.count <= 1 else { return nil }

        // Ids are server-assigned positives, so a negative is malformed
        // rather than absent.
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
    /// Shows the destination `url` names.
    ///
    /// - Returns: `false` if `url` names no destination, leaving navigation
    ///   untouched.
    @discardableResult
    func open(_ url: URL) -> Bool {
        guard let link = DeepLink(url) else { return false }

        if let route = link.route {
            crossTo(route, in: link.tab)
        } else {
            // Clearing keeps following the same link twice idempotent.
            selectedTab = link.tab
            clearStack(link.tab)
        }
        return true
    }
}
