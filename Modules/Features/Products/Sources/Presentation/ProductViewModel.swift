// ProductViewModel.swift

import Foundation

public enum ProductLoadingState {
    case loading, loaded, error(Error)
}

@MainActor
@Observable
public final class ProductViewModel {
    private let repository: ProductRepository
    private let emit: (ProductEvent) -> Void

    public private(set) var products: [Product] = []
    public private(set) var loadingState: ProductLoadingState = .loading

    /// - Parameter emit: Receives user actions, discarded by default so
    ///   previews and tests need no navigation wiring. Omitting it in an app
    ///   produces a screen whose buttons do nothing.
    public init(
        repository: ProductRepository,
        emit: @escaping (ProductEvent) -> Void = { _ in }
    ) {
        self.repository = repository
        self.emit = emit
    }

    public func didTapProduct(id: Int) {
        emit(.productTapped(id: id))
    }

    public func getProducts() async {
        await load(policy: .cacheFirst(maxAge: .seconds(3600)))
    }

    /// Pull-to-refresh: always goes to the network.
    public func refresh() async {
        await load(policy: .reload)
    }

    private func load(policy: CachePolicy) async {
        do {
            products = try await repository.getProducts(policy: policy)
            loadingState = .loaded
        } catch {
            loadingState = .error(error)
        }
    }
}
