// ProductDataRepository.swift

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

    private func isCacheFresh(maxAge: Duration) async -> Bool {
        guard let lastSaved = await storage.lastSavedAt() else { return false }
        return dateProvider.now.timeIntervalSince(lastSaved) < Double(maxAge.components.seconds)
    }
}
