// Product.swift

import Foundation

public struct Product: Identifiable, Sendable {
    public let id: Int
    public let title: String
    public let description: String
    public let category: String
    public let price: Decimal
    public let tags: [String]
    public let brand: String?
    public let meta: Meta
    public let thumbnail: String
    public let images: [String]

    public init(
        id: Int,
        title: String,
        description: String,
        category: String,
        price: Decimal,
        tags: [String],
        brand: String?,
        meta: Meta,
        thumbnail: String,
        images: [String]
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.category = category
        self.price = price
        self.tags = tags
        self.brand = brand
        self.meta = meta
        self.thumbnail = thumbnail
        self.images = images
    }
}

public struct Meta: Sendable {
    public let createdAt: Date
    public let updatedAt: Date

    public init(createdAt: Date, updatedAt: Date) {
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
