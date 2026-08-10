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
    func handle(_ event: ProductEvent) {
        switch event {
        case let .productTapped(id):
            push(.product(.detail(id: id)), onto: .products)

        case let .sellerTapped(userId):
            crossTo(.user(.profile(id: userId)), in: .users)
        }
    }
}
