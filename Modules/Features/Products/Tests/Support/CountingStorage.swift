// CountingStorage.swift

import Foundation
import Persistence
import Synchronization

@testable import Products

/// Counts row reads; everything else passes through to the real storage.
final class CountingStorage: ProductStorage {
    private let reads = Mutex(0)
    private let base: ProductStorage

    init(_ base: ProductStorage) {
        self.base = base
    }

    var readCount: Int { reads.withLock { $0 } }

    func getAll() async throws(StorageError) -> [Product] {
        reads.withLock { $0 += 1 }
        return try await base.getAll()
    }

    func get(id: Int) async throws(StorageError) -> Product? {
        reads.withLock { $0 += 1 }
        return try await base.get(id: id)
    }

    func save(_ products: [Product]) async throws(StorageError) {
        try await base.save(products)
    }

    func upsert(_ product: Product) async throws(StorageError) {
        try await base.upsert(product)
    }

    func delete(id: Int) async throws(StorageError) {
        try await base.delete(id: id)
    }

    func deleteAll() async throws(StorageError) {
        try await base.deleteAll()
    }

    func lastSavedAt() async -> Date? {
        await base.lastSavedAt()
    }
}
