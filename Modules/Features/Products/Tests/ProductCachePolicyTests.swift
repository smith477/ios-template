// ProductCachePolicyTests.swift

import APIClient
import AppKit
import Foundation
import Persistence
import Synchronization
import Testing

@testable import Products

/// Counts calls so a test can tell a cache hit from a refetch.
private final class CountingApiClient: ProductApiClient {
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

/// Counts row reads, so a test can tell how many times a request went to the
/// store. Everything else passes straight through to the real storage.
private final class CountingStorage: ProductStorage {
    private let reads = Mutex(0)
    private let base: ProductStorage

    init(_ base: ProductStorage) {
        self.base = base
    }

    var readCount: Int { reads.withLock { $0 } }

    func getAll() async throws(StorageError) -> [Product] {
        reads.withLock { $0 += 1 }
        return try await base.getAll()
    }

    func get(id: Int) async throws(StorageError) -> Product? {
        reads.withLock { $0 += 1 }
        return try await base.get(id: id)
    }

    func save(_ products: [Product]) async throws(StorageError) {
        try await base.save(products)
    }

    func upsert(_ product: Product) async throws(StorageError) {
        try await base.upsert(product)
    }

    func delete(id: Int) async throws(StorageError) {
        try await base.delete(id: id)
    }

    func deleteAll() async throws(StorageError) {
        try await base.deleteAll()
    }

    func lastSavedAt() async -> Date? {
        await base.lastSavedAt()
    }
}

/// A clock that can be moved forward, so a test can age the cache without
/// waiting. `FixedDateProvider` covers the still-clock case; this covers the
/// case where time has to pass mid-test.
private final class MovableDateProvider: DateProvider {
    private let current: Mutex<Date>

    init(_ start: Date) {
        current = Mutex(start)
    }

    var now: Date { current.withLock { $0 } }

    func advance(by interval: TimeInterval) {
        current.withLock { $0 += interval }
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

    /// The freshness check must not read the rows it is about to serve: a
    /// cache hit is one trip to the store, not two.
    @Test
    func aFreshCacheHitReadsStorageOnce() async throws {
        let clock = MovableDateProvider(Date(timeIntervalSince1970: 1_000_000))
        let api = CountingApiClient(products: [makeProduct()])
        let storage = try CountingStorage(makeStorage(dateProvider: clock))
        let repository = ProductDataRepository(
            apiClient: api,
            storage: storage,
            dateProvider: clock
        )

        _ = try await repository.getProducts(policy: .cacheFirst(maxAge: .seconds(3600)))
        clock.advance(by: 60)
        let readsBeforeHit = storage.readCount
        let products = try await repository.getProducts(policy: .cacheFirst(maxAge: .seconds(3600)))

        #expect(storage.readCount - readsBeforeHit == 1)
        #expect(api.fetchCount == 1)
        #expect(products.map(\.id) == [1])
    }

    /// A fresh timestamp over an empty store is a miss: the emptiness check
    /// moved out of the freshness check, and must still send this to the
    /// network rather than serve an empty catalogue.
    @Test
    func aFreshTimestampOverAnEmptyStoreFetches() async throws {
        let clock = FixedDateProvider(Date(timeIntervalSince1970: 1_000_000))
        let api = CountingApiClient(products: [makeProduct()])
        let storage = try makeStorage(dateProvider: clock)
        try await storage.save([])
        #expect(await storage.lastSavedAt() != nil)
        let repository = ProductDataRepository(
            apiClient: api,
            storage: storage,
            dateProvider: clock
        )

        let products = try await repository.getProducts(policy: .cacheFirst(maxAge: .seconds(3600)))

        #expect(api.fetchCount == 1)
        #expect(products.map(\.id) == [1])
    }
}
