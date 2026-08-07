// ProductViewModel.swift

import Foundation

public enum ProductLoadingState {
    case loading, loaded, error(Error)
}

@MainActor
@Observable
public final class ProductViewModel {
    private let repository: ProductRepository

    public private(set) var products: [Product] = []
    public private(set) var loadingState: ProductLoadingState = .loading

    public init(repository: ProductRepository) {
        self.repository = repository
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
