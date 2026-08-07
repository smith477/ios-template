// ProductStorage.swift

import AppKit
import CoreData
import Foundation
import Persistence

/// Defines local storage operations for Product entities.
public protocol ProductStorage: Sendable {
    func getAll() async throws(StorageError) -> [Product]
    func get(id: Int) async throws(StorageError) -> Product?
    func save(_ products: [Product]) async throws(StorageError)
    func delete(id: Int) async throws(StorageError)
    func deleteAll() async throws(StorageError)

    /// When `save(_:)` last completed, or nil if nothing has been cached.
    ///
    /// This is the cache's own age. `Meta.updatedAt` comes from the API and
    /// describes the product, not when it was last read.
    func lastSavedAt() async -> Date?
}

/// Records when the products cache was last written.
///
/// This persists a timestamp; it does not read the current time. The clock
/// itself is `DateProvider` — keeping the two apart is what lets a test set
/// "now" without also having to fake the stored value.
///
/// `UserDefaults` is documented as thread-safe but is not marked `Sendable`,
/// so the conformance is asserted here rather than at every use site.
struct ProductCacheTimestamp: @unchecked Sendable {
    private let defaults: UserDefaults
    private let key = "products.lastSavedAt"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var lastSavedAt: Date? { defaults.object(forKey: key) as? Date }
    func markSaved(at date: Date) { defaults.set(date, forKey: key) }
    func clear() { defaults.removeObject(forKey: key) }
}

final class ProductCoreDataStorage: ProductStorage {
    private let storageProvider: StorageProvider
    private let timestamp: ProductCacheTimestamp
    private let dateProvider: DateProvider

    init(
        storageProvider: StorageProvider,
        timestamp: ProductCacheTimestamp = ProductCacheTimestamp(),
        dateProvider: DateProvider = SystemDateProvider()
    ) {
        self.storageProvider = storageProvider
        self.timestamp = timestamp
        self.dateProvider = dateProvider
    }

    func lastSavedAt() async -> Date? {
        timestamp.lastSavedAt
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
            timestamp.markSaved(at: dateProvider.now)
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
            timestamp.clear()
        } catch {
            throw .deleteFailed(error)
        }
    }
}
