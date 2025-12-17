// ProductResponse.swift

import Foundation

nonisolated
struct ProductsResponse: Decodable {
    let products: [ProductResponse]
}

nonisolated
struct ProductResponse: Decodable {
    let id: Int
    let title: String
    let description: String
    let category: String
    let price: Double
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

nonisolated
struct DimensionsResponse: Decodable {
    let width: Double
    let height: Double
    let depth: Double
}

nonisolated
struct ReviewResponse: Decodable {
    let rating: Int
    let comment: String
    let date: String
    let reviewerName: String
    let reviewerEmail: String
}

nonisolated
struct MetaResponse: Decodable {
    let createdAt: String
    let updatedAt: String
    let barcode: String
    let qrCode: String

    private static let dateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    func toDomain() -> Meta {
        Meta(
            createdAt: Self.dateFormatter.date(from: createdAt) ?? Date(),
            updatedAt: Self.dateFormatter.date(from: updatedAt) ?? Date()
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

extension Array where Element == ProductResponse {
    func toDomain() -> [Product] {
        map { $0.toDomain() }
    }
}
