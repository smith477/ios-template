// DetailAfterListTests.swift

import APIClient
import AppKit
import Foundation
import Persistence
import Testing

@testable import Products

/// Reproduces the app's real sequence: the list screen loads through one
/// repository, then the detail screen reads the same store through a second
/// repository built independently.
@MainActor
struct DetailAfterListTests {
    @Test
    func detailLoadsAfterTheListHasCached() async throws {
        let provider = try StorageProvider.inMemory(modelName: "ios_template")
        let defaults = UserDefaults(suiteName: UUID().uuidString)!
        let clock = FixedDateProvider(Date())

        func makeRepository() -> ProductDataRepository {
            ProductDataRepository(
                apiClient: StubClient(),
                storage: ProductCoreDataStorage(
                    storageProvider: provider,
                    timestamp: ProductCacheTimestamp(defaults: defaults),
                    dateProvider: clock
                ),
                dateProvider: clock
            )
        }

        let list = ProductViewModel(repository: makeRepository())
        await list.getProducts()
        #expect(list.products.count == 1)

        let detail = ProductDetailViewModel(repository: makeRepository(), id: 1)
        await detail.load()

        guard case let .loaded(product) = detail.state else {
            Issue.record("detail did not load: \(detail.state)")
            return
        }
        #expect(product.id == 1)
    }
}

private struct StubClient: ProductApiClient {
    func fetchProducts() async throws(APIError) -> [Product] {
        [Product(
            id: 1,
            title: "Test",
            description: "d",
            category: "c",
            price: 1,
            tags: [],
            brand: "b",
            meta: Meta(createdAt: Date(), updatedAt: Date()),
            thumbnail: "",
            images: []
        )]
    }
}
