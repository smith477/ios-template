// ProductStorage.swift

import AppKit
import CoreData
import Foundation
import Persistence

/// Defines local storage operations for Product entities.
public protocol ProductStorage: Sendable {
    /// The products the last `save(_:)` was given, sorted by title — the list
    /// as the API last returned it, not every row in the store.
    func getAll() async throws(StorageError) -> [Product]
    func get(id: Int) async throws(StorageError) -> Product?
    /// Saves the list: writes the rows, then records them as the list.
    func save(_ products: [Product]) async throws(StorageError)
    /// Writes one product's row without touching the list or its age, so
    /// opening a product neither adds it to the list nor makes a stale list
    /// look fresh.
    func upsert(_ product: Product) async throws(StorageError)
    func delete(id: Int) async throws(StorageError)
    func deleteAll() async throws(StorageError)

    /// When `save(_:)` last completed — the cache's own age, unlike
    /// `Meta.updatedAt`, which comes from the API and describes the product.
    func lastSavedAt() async -> Date?
}

/// Records the list as last saved: when, and which products it held. The
/// store keeps every product it has seen, so the ids are what tell the list's
/// rows apart from ones cached for another reason. The clock itself is
/// `DateProvider`, so a test can set "now" without faking the stored value.
///
/// Holds a suite name rather than a `UserDefaults`, which is not `Sendable`;
/// `nil` is the standard defaults.
struct ProductListRecord: Sendable {
    private let suiteName: String?
    private let savedAtKey = "products.lastSavedAt"
    private let idsKey = "products.listIds"

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

    var lastSavedAt: Date? { defaults.object(forKey: savedAtKey) as? Date }

    /// Empty for a record written before ids were kept, which reads as an
    /// empty list and so as a cache miss: an upgraded install refetches once.
    var ids: [Int] { defaults.array(forKey: idsKey) as? [Int] ?? [] }

    func markSaved(ids: [Int], at date: Date) {
        defaults.set(ids, forKey: idsKey)
        defaults.set(date, forKey: savedAtKey)
    }

    func clear() {
        defaults.removeObject(forKey: idsKey)
        defaults.removeObject(forKey: savedAtKey)
    }
}

final class ProductCoreDataStorage: ProductStorage {
    private let storageProvider: StorageProvider
    private let listRecord: ProductListRecord
    private let dateProvider: DateProvider

    init(
        storageProvider: StorageProvider,
        listRecord: ProductListRecord = ProductListRecord(),
        dateProvider: DateProvider = SystemDateProvider()
    ) {
        self.storageProvider = storageProvider
        self.listRecord = listRecord
        self.dateProvider = dateProvider
    }

    func lastSavedAt() async -> Date? {
        listRecord.lastSavedAt
    }

    func getAll() async throws(StorageError) -> [Product] {
        let ids = listRecord.ids
        guard !ids.isEmpty else { return [] }
        do {
            return try await storageProvider.performBackground { context in
                let request = ProductEntity.fetchRequest()
                request.predicate = NSPredicate(format: "id IN %@", ids)
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
        try await write(products)
        listRecord.markSaved(ids: products.map(\.id), at: dateProvider.now)
    }

    func upsert(_ product: Product) async throws(StorageError) {
        try await write([product])
    }

    private func write(_ products: [Product]) async throws(StorageError) {
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
            listRecord.clear()
        } catch {
            throw .deleteFailed(error)
        }
    }
}
