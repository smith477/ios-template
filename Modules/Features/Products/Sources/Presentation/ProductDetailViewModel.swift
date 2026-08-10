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

    /// - Parameters:
    ///   - repository: Source of the product.
    ///   - id: Which product to show.
    ///   - emit: Receives user actions. Defaults to discarding them; see
    ///     `ProductViewModel.init(repository:emit:)`.
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

    /// A placeholder seller, derived from the product so that it varies
    /// between products and is stable for any one of them.
    ///
    /// - Note: The API exposes no seller relationship. Replace this with
    ///   `product.sellerId` once it does. The range matches the user ids the
    ///   users endpoint returns (1...30).
    private static func sellerId(for product: Product) -> Int {
        product.id % 30 + 1
    }
}
