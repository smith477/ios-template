// ProductDetailViewModel.swift

import Foundation

public enum ProductDetailState {
    case loading
    case loaded(Product)
    case notFound
    case error(Error)
}

@MainActor
@Observable
public final class ProductDetailViewModel {
    private let repository: ProductRepository
    private let id: Int
    private let emit: (ProductEvent) -> Void

    public private(set) var state: ProductDetailState = .loading

    /// Creates a view model for the product with `id`.
    ///
    /// - Parameter emit: Receives user actions; discarded by default, for previews
    ///   and tests.
    public init(
        repository: ProductRepository,
        id: Int,
        emit: @escaping (ProductEvent) -> Void = { _ in }
    ) {
        self.repository = repository
        self.id = id
        self.emit = emit
    }

    public func load() async {
        do {
            if let product = try await repository.getProduct(id: id) {
                state = .loaded(product)
            } else {
                state = .notFound
            }
        } catch {
            state = .error(error)
        }
    }

    public func didTapSeller() {
        guard case let .loaded(product) = state else { return }
        emit(.sellerTapped(userId: Self.sellerId(for: product)))
    }

    /// A placeholder seller id in the users endpoint's range (1...30), since the
    /// API has no seller. Replace with `product.sellerId` once it does.
    private static func sellerId(for product: Product) -> Int {
        product.id % 30 + 1
    }
}
