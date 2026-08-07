// ProductStorage.swift

import CoreData
import Foundation

/// Defines local storage operations for Product entities.
public protocol ProductStorage: Sendable {
    func getAll() async throws(StorageError) -> [Product]
    func get(id: Int) async throws(StorageError) -> Product?
    func save(_ products: [Product]) async throws(StorageError)
    func delete(id: Int) async throws(StorageError)
    func deleteAll() async throws(StorageError)
}

final class ProductCoreDataStorage: ProductStorage {
    private let storageProvider: StorageProvider

    init(storageProvider: StorageProvider) {
        self.storageProvider = storageProvider
    }

    func getAll() async throws(StorageError) -> [Product] {
        do {
            return try await storageProvider.performBackground { context in
                let request = ProductEntity.fetchRequest()
                request.sortDescriptors = [
                    NSSortDescriptor(keyPath: \ProductEntity.title, ascending: true),
                ]
                let entities = try context.fetch(request)
                return entities.map { $0.toDomain() }
            }
        } catch {
            throw .fetchFailed(error)
        }
    }

    func get(id: Int) async throws(StorageError) -> Product? {
        do {
            return try await storageProvider.performBackground { context in
                let request = ProductEntity.fetchRequest()
                request.predicate = NSPredicate(format: "id == %d", id)
                request.fetchLimit = 1
                return try context.fetch(request).first?.toDomain()
            }
        } catch {
            throw .fetchFailed(error)
        }
    }

    func save(_ products: [Product]) async throws(StorageError) {
        do {
            try await storageProvider.performBackground { context in
                for product in products {
                    let request = ProductEntity.fetchRequest()
                    request.predicate = NSPredicate(format: "id == %d", product.id)
                    request.fetchLimit = 1

                    let entry = try context.fetch(request).first ?? ProductEntity(context: context)
                    entry.update(from: product, in: context)
                }
                try context.save()
            }
        } catch {
            throw .saveFailed(error)
        }
    }

    func delete(id: Int) async throws(StorageError) {
        do {
            try await storageProvider.performBackground { context in
                let request = ProductEntity.fetchRequest()
                request.predicate = NSPredicate(format: "id == %d", id)
                request.fetchLimit = 1

                if let entry = try context.fetch(request).first {
                    context.delete(entry)
                    try context.save()
                }
            }
        } catch {
            throw .deleteFailed(error)
        }
    }

    func deleteAll() async throws(StorageError) {
        do {
            try await storageProvider.performBackground { context in
                let request = NSFetchRequest<NSFetchRequestResult>(entityName: "ProductEntity")
                let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)
                deleteRequest.resultType = .resultTypeObjectIDs

                let result = try context.execute(deleteRequest) as? NSBatchDeleteResult
                let deletedIDs = result?.result as? [NSManagedObjectID] ?? []

                NSManagedObjectContext.mergeChanges(
                    fromRemoteContextSave: [NSDeletedObjectsKey: deletedIDs],
                    into: [context]
                )
            }
        } catch {
            throw .deleteFailed(error)
        }
    }
}
