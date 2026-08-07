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
        do {
            products = try await repository.getProducts()
            loadingState = .loaded
        } catch {
            loadingState = .error(error)
        }
    }
}
