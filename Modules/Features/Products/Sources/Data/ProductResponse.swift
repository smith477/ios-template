// ProductResponse.swift

import Foundation

struct ProductsResponse: Decodable {
    let products: [ProductResponse]
}

struct ProductResponse: Decodable {
    let id: Int
    let title: String
    let description: String
    let category: String
    // Decoded straight to Decimal: going through Double first would round the
    // value before it is ever stored.
    let price: Decimal
    let discountPercentage: Double
    let rating: Double
    let stock: Int
    let tags: [String]
    let brand: String?
    let sku: String
    let weight: Int
    let dimensions: DimensionsResponse
    let warrantyInformation: String
    let shippingInformation: String
    let availabilityStatus: String
    let reviews: [ReviewResponse]
    let returnPolicy: String
    let minimumOrderQuantity: Int
    let meta: MetaResponse
    let thumbnail: String
    let images: [String]
}

struct DimensionsResponse: Decodable {
    let width: Double
    let height: Double
    let depth: Double
}

struct ReviewResponse: Decodable {
    let rating: Int
    let comment: String
    let date: String
    let reviewerName: String
    let reviewerEmail: String
}

struct MetaResponse: Decodable {
    let createdAt: String
    let updatedAt: String
    let barcode: String
    let qrCode: String

    /// `ISO8601DateFormatter` is a class and not `Sendable`, so a shared
    /// instance would be a data race once decoding happens off the main actor.
    /// The format style is a value type and safe to share.
    private static let dateStyle = Date.ISO8601FormatStyle(includingFractionalSeconds: true)

    func toDomain() -> Meta {
        Meta(
            createdAt: (try? Self.dateStyle.parse(createdAt)) ?? Date(),
            updatedAt: (try? Self.dateStyle.parse(updatedAt)) ?? Date()
        )
    }
}

// MARK: - Domain Mapping

extension ProductResponse {
    func toDomain() -> Product {
        Product(
            id: id,
            title: title,
            description: description,
            category: category,
            price: price,
            tags: tags,
            brand: brand,
            meta: meta.toDomain(),
            thumbnail: thumbnail,
            images: images
        )
    }
}

extension [ProductResponse] {
    func toDomain() -> [Product] {
        map { $0.toDomain() }
    }
}
