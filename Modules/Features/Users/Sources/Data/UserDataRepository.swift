// UserDataRepository.swift

import Foundation
import Identity

final class UserDataRepository: UserRepository {
    private let apiClient: UserApiClient
    private let storage: UserStorage

    init(apiClient: UserApiClient, storage: UserStorage) {
        self.apiClient = apiClient
        self.storage = storage
    }

    func getUsers() async throws -> [User] {
        let cached = try await storage.getAll()
        if cached.isEmpty {
            let users = try await apiClient.fetchUsers()
            try await storage.save(users)
            return try await storage.getAll()
        }
        return cached
    }
}
