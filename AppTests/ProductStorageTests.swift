//
//  ProductStorageTests.swift
//  AppTests
//

import Foundation
import Persistence
import Products
import Testing

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

    /// Saving the same product twice used to delete every image and tag row and
    /// recreate them. With the cascade rules pointing child to parent, that
    /// deletion took the product with it.
    @Test
    func repeatedSavesKeepTheProduct() async throws {
        let storage = ProductsTesting.makeStorage(
            storageProvider: try .inMemory(modelName: "ios_template")
        )
        let product = makeProduct()

        try await storage.save([product])
        try await storage.save([product])
        try await storage.save([product])

        let stored = try await storage.getAll()
        #expect(stored.count == 1)
        #expect(stored.first?.images.count == 2)
        #expect(stored.first?.tags.count == 2)
    }

    /// Children that disappear from the payload are removed; children that stay
    /// are left alone rather than deleted and rebuilt.
    @Test
    func updateDiffsChildren() async throws {
        let storage = ProductsTesting.makeStorage(
            storageProvider: try .inMemory(modelName: "ios_template")
        )

        try await storage.save([makeProduct(tags: ["a", "b"], images: ["one.jpg", "two.jpg"])])
        try await storage.save([makeProduct(tags: ["b", "c"], images: ["two.jpg"])])

        let stored = try #require(try await storage.getAll().first)
        #expect(Set(stored.tags) == ["b", "c"])
        #expect(stored.images == ["two.jpg"])
    }

    /// Money is stored as a decimal, so a price that is not representable in
    /// binary floating point survives the round trip exactly.
    @Test
    func priceRoundTripsExactly() async throws {
        let storage = ProductsTesting.makeStorage(
            storageProvider: try .inMemory(modelName: "ios_template")
        )

        try await storage.save([makeProduct(price: Decimal(string: "19.99")!)])

        let stored = try #require(try await storage.getAll().first)
        #expect(stored.price == Decimal(string: "19.99")!)
    }
}
