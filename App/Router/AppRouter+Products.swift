// AppRouter+Products.swift

import Products
import Users

/// Maps `ProductEvent` to navigation. Imports `Users` because a product's
/// seller is a user — cross-feature coupling belongs here, not in the module.
extension AppRouter {
    func handle(_ event: ProductEvent) {
        switch event {
        case let .productTapped(id):
            push(.product(.detail(id: id)), onto: .products)

        // Pushed onto the Products stack rather than crossing tabs, so Back
        // returns to the product and the Users tab keeps what the user left.
        case let .sellerTapped(userId):
            push(.user(.profile(id: userId)), onto: .products)
        }
    }
}
