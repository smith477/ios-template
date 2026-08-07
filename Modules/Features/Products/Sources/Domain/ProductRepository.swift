// ProductRepository.swift

import Foundation

public protocol ProductRepository: Sendable {
    func getProducts() async throws -> [Product]
}
