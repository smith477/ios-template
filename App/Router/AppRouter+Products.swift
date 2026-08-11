// AppRouter+Products.swift

import Products
import Users

/// Maps `ProductEvent` to navigation.
///
/// One file per feature so that adding a feature does not edit a shared one.
/// Imports `Users` because a product's seller is a user — cross-feature
/// coupling belongs here, in the app, not in the Products module.
extension AppRouter {
    /// Routes an event emitted by the Products feature.
    ///
    /// Every destination lands on the Products stack, because that is where
    /// this feature is shown. Should a second tab ever display a product, this
    /// has to take the originating tab as a parameter rather than naming
    /// `.products` — see `AppRouter`'s note on passing context to `handle(_:)`.
    func handle(_ event: ProductEvent) {
        switch event {
        case let .productTapped(id):
            push(.product(.detail(id: id)), onto: .products)

        // A seller is a screen about the product being viewed, so it pushes on
        // top of it: Back returns to the product, and the Users tab keeps
        // whatever the user left there. Reaching a profile this way builds a
        // second one, separate from any in the Users tab — fine while a profile
        // only reads, and a shared source of truth if one ever edits.
        case let .sellerTapped(userId):
            push(.user(.profile(id: userId)), onto: .products)
        }
    }
}
