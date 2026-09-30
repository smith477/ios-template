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

    /// When `save(_:)` last completed — the cache's own age, unlike
    /// `Meta.updatedAt`, which comes from the API and describes the product.
    func lastSavedAt() async -> Date?
}

/// Records when the products cache was last written. Persists a timestamp
/// only; the clock itself is `DateProvider`, so a test can set "now" without
/// faking the stored value.
///
/// Holds a suite name rather than a `UserDefaults`, which is not `Sendable`;
/// `nil` is the standard defaults.
struct ProductCacheTimestamp: Sendable {
    private let suiteName: String?
    private let key = "products.lastSavedAt"

    init(suiteName: String? = nil) {
        self.suiteName = suiteName
    }

    private var defaults: UserDefaults {
        guard let suiteName else { return .standard }
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            fatalError("UserDefaults rejected the suite name \(suiteName)")
        }
        return defaults
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
