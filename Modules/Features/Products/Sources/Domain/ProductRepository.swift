// ProductRepository.swift

import Foundation

/// How a read should treat what is already in the store.
public enum CachePolicy: Sendable {
    /// Serve the cached copy while it is younger than `maxAge`, otherwise fetch.
    case cacheFirst(maxAge: Duration)
    /// Always fetch, and replace what is cached.
    case reload
}

public protocol ProductRepository: Sendable {
    func getProducts(policy: CachePolicy) async throws -> [Product]
    /// `nil` when the API no longer has the product.
    func getProduct(id: Int, policy: CachePolicy) async throws -> Product?
}

public extension ProductRepository {
    /// The default read: an hour-old catalogue is good enough to show
    /// immediately, and pull-to-refresh passes `.reload`.
    func getProducts() async throws -> [Product] {
        try await getProducts(policy: .cacheFirst(maxAge: .seconds(3600)))
    }

    /// The same hour as the list, measured from the list's last save.
    func getProduct(id: Int) async throws -> Product? {
        try await getProduct(id: id, policy: .cacheFirst(maxAge: .seconds(3600)))
    }
}
