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

    /// - Parameter emit: Receives user actions, discarded by default so
    ///   previews and tests need no navigation wiring.
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
            let products = try await repository.getProducts()
            if let product = products.first(where: { $0.id == id }) {
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

    /// A placeholder seller: the API exposes no seller relationship, so this
    /// derives a stable id in the range the users endpoint returns (1...30).
    /// Replace with `product.sellerId` once the API has one.
    private static func sellerId(for product: Product) -> Int {
        product.id % 30 + 1
    }
}
