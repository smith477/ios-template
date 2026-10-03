// ProductCachePolicyTests.swift

import Foundation
import Testing

@testable import Products

struct ProductCachePolicyTests {
    @Test
    func cacheFirstServesFromCacheWhileFresh() async throws {
        let clock = MovableDateProvider(Date(timeIntervalSince1970: 1_000_000))
        let api = CountingApiClient(products: [.fixture()])
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

    @Test
    func cacheFirstRefetchesOnceStale() async throws {
        let clock = MovableDateProvider(Date(timeIntervalSince1970: 1_000_000))
        let api = CountingApiClient(products: [.fixture()])
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

    @Test
    func reloadAlwaysRefetches() async throws {
        let clock = FixedDateProvider(Date(timeIntervalSince1970: 1_000_000))
        let api = CountingApiClient(products: [.fixture()])
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

    @Test
    func aFreshCacheHitReadsStorageOnce() async throws {
        let clock = MovableDateProvider(Date(timeIntervalSince1970: 1_000_000))
        let api = CountingApiClient(products: [.fixture()])
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

    @Test
    func aFreshTimestampOverAnEmptyStoreFetches() async throws {
        let clock = FixedDateProvider(Date(timeIntervalSince1970: 1_000_000))
        let api = CountingApiClient(products: [.fixture()])
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
