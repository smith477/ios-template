// ProductDataRepository.swift

import Foundation

final class ProductDataRepository: ProductRepository {
    private let apiClient: ProductApiClient
    private let storage: ProductStorage
    private let now: @Sendable () -> Date

    init(
        apiClient: ProductApiClient,
        storage: ProductStorage,
        now: @escaping @Sendable () -> Date = { Date() }
    ) {
        self.apiClient = apiClient
        self.storage = storage
        self.now = now
    }

    func getProducts(policy: CachePolicy) async throws -> [Product] {
        if case let .cacheFirst(maxAge) = policy, try await isCacheFresh(maxAge: maxAge) {
            return try await storage.getAll()
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

    private func isCacheFresh(maxAge: Duration) async throws -> Bool {
        guard let lastSaved = await storage.lastSavedAt() else { return false }
        guard try await !storage.getAll().isEmpty else { return false }
        return now().timeIntervalSince(lastSaved) < Double(maxAge.components.seconds)
    }
}
