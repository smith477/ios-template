// ProductDataRepository.swift

import APIClient
import AppKit
import Foundation

final class ProductDataRepository: ProductRepository {
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
            if !cached.isEmpty { return cached }
        }

        do {
            let products = try await apiClient.fetchProducts()
            try await storage.save(products)
        } catch {
            // A failed refresh should not empty the screen: fall back to
            // whatever is cached, and only surface the error if there is
            // nothing to show.
            let cached = try await storage.getAll()
            if cached.isEmpty { throw error }
            return cached
        }
        return try await storage.getAll()
    }

    /// Freshness is the list's: a product has no age of its own, so a cached
    /// row is served while the list is fresh. Saving it leaves the list alone.
    func getProduct(id: Int, policy: CachePolicy) async throws -> Product? {
        if case let .cacheFirst(maxAge) = policy, await isCacheFresh(maxAge: maxAge),
           let cached = try await storage.get(id: id) {
            return cached
        }

        let product: Product
        do {
            product = try await apiClient.fetchProduct(id: id)
        } catch .notFound {
            // The API's answer, not a failed request: the product is gone,
            // so its cached copy must not be served in its place.
            try await storage.delete(id: id)
            return nil
        } catch {
            // As for the list: a failed refresh falls back to the cached
            // copy, and only surfaces the error when there is none.
            if let cached = try await storage.get(id: id) { return cached }
            throw error
        }
        try await storage.upsert(product)
        return product
    }

    private func isCacheFresh(maxAge: Duration) async -> Bool {
        guard let lastSaved = await storage.lastSavedAt() else { return false }
        return dateProvider.now.timeIntervalSince(lastSaved) < Double(maxAge.components.seconds)
    }
}
