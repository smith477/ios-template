// Product.swift

import Foundation

// MARK: - Products Response

struct Products: Decodable {
    let products: [Product]
    let total: Int
    let skip: Int
    let limit: Int
}

// MARK: - Product

public struct Product: Decodable, Identifiable, Sendable {
    public let id: Int
    public let title: String
    public let description: String
    public let category: String
    public let price: Double
    public let tags: [String]
    public let brand: String?
    public let meta: Meta
    public let thumbnail: String
    public let images: [String]
}

// MARK: - Meta

public struct Meta: Decodable, Sendable {
    public let createdAt: Date
    public let updatedAt: Date
}
