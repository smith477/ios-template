// ProductApiClient.swift

import APIClient
import Foundation

public protocol ProductApiClient {
    func fetchProducts() async throws(APIError) -> [Product]
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
}

enum ProductEndpoint: Endpoint {
    case list

    var path: String {
        switch self {
        case .list:
            return "/products"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .list: return .GET
        }
    }
}

