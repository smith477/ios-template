//
//  ProductCachePolicyTests.swift
//  ProductsTests
//

import APIClient
import AppKit
import Foundation
import Persistence
import Testing

@testable import Products

/// Counts calls so a test can tell a cache hit from a refetch.
private final class CountingApiClient: ProductApiClient, @unchecked Sendable {
    private(set) var fetchCount = 0
    private let products: [Product]

    init(products: [Product]) {
        self.products = products
    }

    func fetchProducts() async throws(APIError) -> [Product] {
        fetchCount += 1
        return products
    }
}

/// A clock that can be moved forward, so a test can age the cache without
/// waiting. `FixedDateProvider` covers the still-clock case; this covers the
/// case where time has to pass mid-test.
private final class MovableDateProvider: DateProvider, @unchecked Sendable {
    private var current: Date

    init(_ start: Date) {
        current = start
    }

    var now: Date { current }

    func advance(by interval: TimeInterval) {
        current += interval
    }
}

struct ProductCachePolicyTests {
    private func makeProduct(id: Int = 1) -> Product {
        Product(
            id: id,
            title: "Widget",
            description: "",
            category: "",
            price: 9.99,
            tags: [],
            brand: nil,
            meta: Meta(createdAt: Date(), updatedAt: Date()),
            thumbnail: "",
            images: []
        )
    }

    /// Two reads inside `maxAge` hit the network once. The second is served
    /// from the cache.
    @Test
    func cacheFirstServesFromCacheWhileFresh() async throws {
        let clock = MovableDateProvider(Date(timeIntervalSince1970: 1_000_000))
        let api = CountingApiClient(products: [makeProduct()])
        let storage = try makeStorage(dateProvider: clock)
        let repository = ProductDataRepository(
            apiClient: api,
            storage: storage,
            dateProvider: clock
        )

        _ = try await repository.getProducts(policy: .cacheFirst(maxAge: .seconds(3600)))
        clock.advance(by: 60)
        _ = try await repository.getProducts(policy: .cacheFirst(maxAge: .seconds(3600)))

        #expect(api.fetchCount == 1)
    }

    /// Once the cache is older than `maxAge`, the next read refetches. This is
    /// the case the wall clock could not test — it would have meant sleeping
    /// for an hour.
    @Test
    func cacheFirstRefetchesOnceStale() async throws {
        let clock = MovableDateProvider(Date(timeIntervalSince1970: 1_000_000))
        let api = CountingApiClient(products: [makeProduct()])
        let storage = try makeStorage(dateProvider: clock)
        let repository = ProductDataRepository(
            apiClient: api,
            storage: storage,
            dateProvider: clock
        )

        _ = try await repository.getProducts(policy: .cacheFirst(maxAge: .seconds(3600)))
        clock.advance(by: 3601)
        _ = try await repository.getProducts(policy: .cacheFirst(maxAge: .seconds(3600)))

        #expect(api.fetchCount == 2)
    }

    /// `.reload` ignores a fresh cache entirely.
    @Test
    func reloadAlwaysRefetches() async throws {
        let clock = FixedDateProvider(Date(timeIntervalSince1970: 1_000_000))
        let api = CountingApiClient(products: [makeProduct()])
        let storage = try makeStorage(dateProvider: clock)
        let repository = ProductDataRepository(
            apiClient: api,
            storage: storage,
            dateProvider: clock
        )

        _ = try await repository.getProducts(policy: .reload)
        _ = try await repository.getProducts(policy: .reload)

        #expect(api.fetchCount == 2)
    }
}
