// ProductStorageTests.swift

// A literal price that fails to parse should fail the test on the spot.
// swiftlint:disable force_unwrapping

import Foundation
import Persistence
import Testing

@testable import Products

struct ProductStorageTests {
    private func makeProduct(
        id: Int = 1,
        title: String = "Widget",
        price: Decimal = 9.99,
        tags: [String] = ["a", "b"],
        images: [String] = ["one.jpg", "two.jpg"]
    ) -> Product {
        Product(
            id: id,
            title: title,
            description: "",
            category: "",
            price: price,
            tags: tags,
            brand: nil,
            meta: Meta(createdAt: Date(), updatedAt: Date()),
            thumbnail: "",
            images: images
        )
    }

    /// The cascade rules point child to parent, so deleting children on save would
    /// take the product with them.
    @Test
    func repeatedSavesKeepTheProduct() async throws {
        let storage = try makeStorage()
        let product = makeProduct()

        try await storage.save([product])
        try await storage.save([product])
        try await storage.save([product])

        let stored = try await storage.getAll()
        #expect(stored.count == 1)
        #expect(stored.first?.images.count == 2)
        #expect(stored.first?.tags.count == 2)
    }

    @Test
    func updateDiffsChildren() async throws {
        let storage = try makeStorage()

        try await storage.save([makeProduct(tags: ["a", "b"], images: ["one.jpg", "two.jpg"])])
        try await storage.save([makeProduct(tags: ["b", "c"], images: ["two.jpg"])])

        let stored = try #require(try await storage.getAll().first)
        #expect(Set(stored.tags) == ["b", "c"])
        #expect(stored.images == ["two.jpg"])
    }

    @Test
    func priceRoundTripsExactly() async throws {
        let storage = try makeStorage()

        try await storage.save([makeProduct(price: Decimal(string: "19.99")!)])

        let stored = try #require(try await storage.getAll().first)
        #expect(stored.price == Decimal(string: "19.99")!)
    }

    /// Their rows stay cached; only the list forgets them.
    @Test
    func aListSaveDropsProductsTheNextListOmits() async throws {
        let storage = try makeStorage()

        try await storage.save([makeProduct(id: 1, title: "A"), makeProduct(id: 2, title: "B")])
        try await storage.save([makeProduct(id: 1, title: "A")])

        #expect(try await storage.getAll().map(\.id) == [1])
        #expect(try await storage.get(id: 2) != nil)
    }

    /// A timestamp with no ids, as written before ids were kept.
    @Test
    func aRecordWithNoIdsReadsAsEmpty() async throws {
        let provider = try StorageProvider.inMemory(modelName: "ios_template")
        let writer = ProductCoreDataStorage(
            storageProvider: provider,
            listRecord: ProductListRecord(suiteName: UUID().uuidString)
        )
        try await writer.save([makeProduct(id: 1)])

        let legacySuite = UUID().uuidString
        let legacyDefaults = try #require(UserDefaults(suiteName: legacySuite))
        legacyDefaults.set(Date(), forKey: "products.lastSavedAt")
        let reader = ProductCoreDataStorage(
            storageProvider: provider,
            listRecord: ProductListRecord(suiteName: legacySuite)
        )

        #expect(await reader.lastSavedAt() != nil)
        #expect(try await reader.getAll().isEmpty)
    }
}
