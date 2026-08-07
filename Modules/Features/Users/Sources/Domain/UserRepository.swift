// UserRepository.swift

import Foundation

public protocol UserRepository: Sendable {
    func getUsers() async throws -> [User]
}
