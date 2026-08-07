// UserStorage.swift

import CoreData
import Foundation
import Identity
import Persistence

protocol UserStorage: Sendable {
    func getAll() async throws(StorageError) -> [User]
    func save(_ users: [User]) async throws(StorageError)
}

final class UserCoreDataStorage: UserStorage {
    private let storageProvider: StorageProvider

    init(storageProvider: StorageProvider) {
        self.storageProvider = storageProvider
    }

    func getAll() async throws(StorageError) -> [User] {
        do {
            return try await storageProvider.performBackground { context in
                let request = UserEntity.fetchRequest()
                request.sortDescriptors = [
                    NSSortDescriptor(keyPath: \UserEntity.firstName, ascending: true),
                ]
                return try context.fetch(request).map { $0.toDomain() }
            }
        } catch {
            throw .fetchFailed(error)
        }
    }

    func save(_ users: [User]) async throws(StorageError) {
        do {
            try await storageProvider.performBackground { context in
                for user in users {
                    let request = UserEntity.fetchRequest()
                    request.predicate = NSPredicate(format: "id == %d", user.id)
                    request.fetchLimit = 1

                    let entry = try context.fetch(request).first ?? UserEntity(context: context)
                    entry.update(from: user)
                }
                try context.save()
            }
        } catch {
            throw .saveFailed(error)
        }
    }
}
