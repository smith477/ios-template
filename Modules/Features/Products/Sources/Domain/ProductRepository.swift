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
    /// Returns the product with `id`, or `nil` when the API no longer has it.
    func getProduct(id: Int, policy: CachePolicy) async throws -> Product?
}

public extension ProductRepository {
    /// Reads the list, serving a cache up to an hour old.
    func getProducts() async throws -> [Product] {
        try await getProducts(policy: .cacheFirst(maxAge: .seconds(3600)))
    }

    /// Reads one product, serving a cache up to an hour old.
    func getProduct(id: Int) async throws -> Product? {
        try await getProduct(id: id, policy: .cacheFirst(maxAge: .seconds(3600)))
    }
}
