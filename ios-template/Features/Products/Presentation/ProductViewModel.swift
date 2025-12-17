// ProductViewModel.swift

import Foundation

enum ProductLoadingsState {
    case loading, loaded, error(error: Error)
}

@Observable
class ProductViewModel {
    private let repository: ProductRepository

    private(set) var products: [Product] = []
    var loadingState: ProductLoadingsState = .loading

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
            loadingState = .error(error: error)
        }
    }
}
