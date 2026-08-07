// UserApiClient.swift

import APIClient
import Foundation

protocol UserApiClient: Sendable {
    func fetchUsers() async throws(APIError) -> [User]
}

final class UserAPISessionClient: UserApiClient {
    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func fetchUsers() async throws(APIError) -> [User] {
        let response: UsersResponse = try await apiClient.send(UserEndpoint.list)
        return response.users.map { $0.toDomain() }
    }
}

enum UserEndpoint: Endpoint {
    case list

    var path: String {
        switch self {
        case .list: return "/users"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .list: return .GET
        }
    }
}
