// Product+Fixture.swift

import Foundation

@testable import Products

extension Product {
    /// A product with placeholder values for every field a test does not name.
    static func fixture(id: Int = 1, title: String = "Widget") -> Product {
        Product(
            id: id,
            title: title,
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
}
