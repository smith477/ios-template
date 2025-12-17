// ProductRepository.swift

import Foundation

public protocol ProductRepository {
    func getProducts() async throws -> [Product]
}

final class ProductDataRepository: ProductRepository {
    private let apiClient: ProductApiClient
    private let storage: ProductStorage

    init(apiClient: ProductApiClient, storage: ProductStorage) {
        self.apiClient = apiClient
        self.storage = storage
    }

    func getProducts() async throws -> [Product] {
        let result = try await storage.getAll()
        if result.isEmpty {
            let products = try await apiClient.fetchProducts()
            try await storage.save(products)
            return try await storage.getAll()
        } else {
            return result
        }
    }
}
