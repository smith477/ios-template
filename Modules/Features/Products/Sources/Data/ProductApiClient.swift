// ProductApiClient.swift

import APIClient
import Foundation

public protocol ProductApiClient: Sendable {
    func fetchProducts() async throws(APIError) -> [Product]
    func fetchProduct(id: Int) async throws(APIError) -> Product
}

final class ProductAPISessionClient: ProductApiClient {
    let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func fetchProducts() async throws(APIError) -> [Product] {
        let response: ProductsResponse = try await apiClient.send(ProductEndpoint.list)
        return response.products.toDomain()
    }

    func fetchProduct(id: Int) async throws(APIError) -> Product {
        let response: ProductResponse = try await apiClient.send(ProductEndpoint.detail(id: id))
        return response.toDomain()
    }
}

enum ProductEndpoint: Endpoint {
    case list
    case detail(id: Int)

    var path: String {
        switch self {
        case .list:
            "/products"
        case let .detail(id):
            "/products/\(id)"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .list, .detail: .GET
        }
    }
}
