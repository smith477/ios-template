// ProductDataRepository.swift

import APIClient
import Diagnostics
import Foundation

final class ProductDataRepository: ProductRepository {
    private static let log = Log()

    private let apiClient: ProductApiClient
    private let storage: ProductStorage
    private let dateProvider: DateProvider

    init(
        apiClient: ProductApiClient,
        storage: ProductStorage,
        dateProvider: DateProvider = SystemDateProvider()
    ) {
        self.apiClient = apiClient
        self.storage = storage
        self.dateProvider = dateProvider
    }

    func getProducts(policy: CachePolicy) async throws -> [Product] {
        // One read serves both the emptiness check and the result: a fresh
        // timestamp over an empty store is a miss, not an empty catalogue.
        if case let .cacheFirst(maxAge) = policy, await isCacheFresh(maxAge: maxAge) {
            let cached = try await storage.getAll()
            if !cached.isEmpty {
                Self.log.debug("Served cached products", ["count": cached.count])
                return cached
            }
        }

        do {
            let products = try await apiClient.fetchProducts()
            try await storage.save(products)
            Self.log.debug("Fetched products", ["count": products.count])
        } catch {
            // A failed refresh falls back to the cache, and only throws when the cache is
            // empty.
            let cached = try await storage.getAll()
            if cached.isEmpty {
                Self.log.error("Products refresh failed with nothing cached", error: error)
                throw error
            }
            Self.log.notice("Products refresh failed; served the cache", error: error, ["count": cached.count])
            return cached
        }
        return try await storage.getAll()
    }

    /// Serves a cached row while the list is fresh: a product has no age of its own.
    func getProduct(id: Int, policy: CachePolicy) async throws -> Product? {
        if case let .cacheFirst(maxAge) = policy, await isCacheFresh(maxAge: maxAge),
           let cached = try await storage.get(id: id) {
            Self.log.debug("Served a cached product", ["id": id])
            return cached
        }

        let product: Product
        do {
            product = try await apiClient.fetchProduct(id: id)
        } catch .notFound {
            // A 404 means the product is gone, so its cached copy is not served.
            try await storage.delete(id: id)
            Self.log.notice("Product is gone; removed its cached copy", ["id": id])
            return nil
        } catch {
            // As for the list, a failed refresh falls back to the cached copy.
            if let cached = try await storage.get(id: id) {
                Self.log.notice("Product refresh failed; served the cache", error: error, ["id": id])
                return cached
            }
            Self.log.error("Product refresh failed with nothing cached", error: error, ["id": id])
            throw error
        }
        try await storage.upsert(product)
        Self.log.debug("Fetched a product", ["id": id])
        return product
    }

    private func isCacheFresh(maxAge: Duration) async -> Bool {
        guard let lastSaved = await storage.lastSavedAt() else { return false }
        return dateProvider.now.timeIntervalSince(lastSaved) < Double(maxAge.components.seconds)
    }
}
