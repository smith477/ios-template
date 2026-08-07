// ProductViewModel.swift

import Foundation

enum ProductLoadingState {
    case loading, loaded, error(Error)
}

@Observable
class ProductViewModel {
    private let repository: ProductRepository

    private(set) var products: [Product] = []
    var loadingState: ProductLoadingState = .loading

    init(repository: ProductRepository) {
        self.repository = repository
    }

    @MainActor
    func getProducts() async {
        do {
            let result = try await repository.getProducts()
            products = result
            loadingState = .loaded
        } catch {
            loadingState = .error(error)
        }
    }
}
