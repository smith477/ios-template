// CountingApiClient.swift

import APIClient
import Synchronization

@testable import Products

/// Counts fetches, to tell a cache hit from a refetch.
final class CountingApiClient: ProductApiClient {
    private let count = Mutex(0)
    private let products: [Product]

    init(products: [Product]) {
        self.products = products
    }

    var fetchCount: Int { count.withLock { $0 } }

    func fetchProducts() async throws(APIError) -> [Product] {
        count.withLock { $0 += 1 }
        return products
    }

    func fetchProduct(id: Int) async throws(APIError) -> Product {
        count.withLock { $0 += 1 }
        guard let product = products.first(where: { $0.id == id }) else { throw .notFound }
        return product
    }
}
