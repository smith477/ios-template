// UserRepository.swift

import Foundation
import Identity

public protocol UserRepository: Sendable {
    func getUsers() async throws -> [User]
}
