// ProductByIdTests.swift

import APIClient
import AppKit
import Foundation
import Persistence
import Synchronization
import Testing

@testable import Products

/// Serves its products by id, answers 404 for any other, or fails with
/// `failure`. Counts by-id fetches.
private final class ByIdApiClient: ProductApiClient {
    private let count = Mutex(0)
    private let products: [Product]
    private let failure: APIError?

    init(products: [Product] = [], failure: APIError? = nil) {
        self.products = products
        self.failure = failure
    }

    var fetchCount: Int { count.withLock { $0 } }

    func fetchProducts() async throws(APIError) -> [Product] {
        products
    }

    func fetchProduct(id: Int) async throws(APIError) -> Product {
        count.withLock { $0 += 1 }
        if let failure { throw failure }
        guard let product = products.first(where: { $0.id == id }) else { throw .notFound }
        return product
    }
}

struct ProductByIdTests {
    private let savedAt = Date(timeIntervalSince1970: 1_000_000)
    private let maxAge = Duration.seconds(3600)

    private func makeProduct(id: Int) -> Product {
        Product(
            id: id,
            title: "Product \(id)",
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

    /// A list of `listed` saved at `savedAt`, read through a repository and storage
    /// whose clock is `secondsLater` on, so a stray stamp would show.
    private func makeRepository(
        api: ByIdApiClient,
        listed: [Product] = [],
        secondsLater: TimeInterval = 60
    ) async throws -> (ProductDataRepository, ProductCoreDataStorage) {
        let provider = try StorageProvider.inMemory(modelName: "ios_template")
        let suiteName = UUID().uuidString
        let now = FixedDateProvider(savedAt.addingTimeInterval(secondsLater))

        let listWriter = ProductCoreDataStorage(
            storageProvider: provider,
            listRecord: ProductListRecord(suiteName: suiteName),
            dateProvider: FixedDateProvider(savedAt)
        )
        if !listed.isEmpty { try await listWriter.save(listed) }

        let storage = ProductCoreDataStorage(
            storageProvider: provider,
            listRecord: ProductListRecord(suiteName: suiteName),
            dateProvider: now
        )
        let repository = ProductDataRepository(apiClient: api, storage: storage, dateProvider: now)
        return (repository, storage)
    }

    @Test
    func aCachedProductIsServedWhileTheListIsFresh() async throws {
        let api = ByIdApiClient(products: [makeProduct(id: 1)])
        let (repository, _) = try await makeRepository(api: api, listed: [makeProduct(id: 1)])

        let product = try await repository.getProduct(id: 1, policy: .cacheFirst(maxAge: maxAge))

        #expect(product?.id == 1)
        #expect(api.fetchCount == 0)
    }

    @Test
    func aProductOutsideTheListIsFetchedOnceThenCached() async throws {
        let api = ByIdApiClient(products: [makeProduct(id: 50)])
        let (repository, storage) = try await makeRepository(api: api, listed: [makeProduct(id: 1)])

        let first = try await repository.getProduct(id: 50, policy: .cacheFirst(maxAge: maxAge))
        let second = try await repository.getProduct(id: 50, policy: .cacheFirst(maxAge: maxAge))

        #expect(first?.id == 50)
        #expect(second?.id == 50)
        #expect(api.fetchCount == 1)
        #expect(try await storage.get(id: 50) != nil)
    }

    @Test
    func aStaleListRefetchesTheProduct() async throws {
        let api = ByIdApiClient(products: [makeProduct(id: 1)])
        let (repository, _) = try await makeRepository(
            api: api,
            listed: [makeProduct(id: 1)],
            secondsLater: 3601
        )

        _ = try await repository.getProduct(id: 1, policy: .cacheFirst(maxAge: maxAge))

        #expect(api.fetchCount == 1)
    }

    @Test
    func aNotFoundDeletesTheCachedRowAndReturnsNil() async throws {
        let api = ByIdApiClient()
        let (repository, storage) = try await makeRepository(api: api, listed: [makeProduct(id: 1)])

        let product = try await repository.getProduct(id: 1, policy: .reload)

        #expect(product == nil)
        #expect(try await storage.get(id: 1) == nil)
        #expect(try await storage.getAll().isEmpty)
    }

    @Test
    func aFailedRefreshFallsBackToTheCachedRow() async throws {
        let api = ByIdApiClient(failure: .networkError("offline"))
        let (repository, _) = try await makeRepository(api: api, listed: [makeProduct(id: 1)])

        let product = try await repository.getProduct(id: 1, policy: .reload)

        #expect(product?.id == 1)
    }

    @Test
    func aFailedRefreshWithNothingCachedThrows() async throws {
        let api = ByIdApiClient(failure: .networkError("offline"))
        let (repository, _) = try await makeRepository(api: api)

        await #expect(throws: APIError.networkError("offline")) {
            _ = try await repository.getProduct(id: 1, policy: .reload)
        }
    }

    @Test
    func aByIdSaveLeavesTheListAlone() async throws {
        let api = ByIdApiClient(products: [makeProduct(id: 50)])
        let (repository, storage) = try await makeRepository(api: api, listed: [makeProduct(id: 1)])

        _ = try await repository.getProduct(id: 50, policy: .reload)

        #expect(try await storage.getAll().map(\.id) == [1])
        #expect(await storage.lastSavedAt() == savedAt)
    }
}
