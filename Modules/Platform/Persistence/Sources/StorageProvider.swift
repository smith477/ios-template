// StorageProvider.swift

import CoreData
import Foundation
import Synchronization

/// The Core Data stack: `viewContext` for main-thread reads,
/// `performBackground(_:)` for writes and heavy reads.
public final class StorageProvider: Sendable {
    private let persistentContainer: NSPersistentContainer

    /// Managed objects fetched here may only be touched on the main thread.
    public var viewContext: NSManagedObjectContext {
        persistentContainer.viewContext
    }

    /// The model ships in this module's resource bundle rather than the app's,
    /// so `Bundle.main` will not find it.
    public static var modelBundle: Bundle { .module }

    /// One model per model file for the whole process: separate copies leave Core
    /// Data unable to resolve `ProductEntity`. Models stay inside the lock because
    /// `NSManagedObjectModel` is not `Sendable`.
    private static let models = Mutex<[URL: NSManagedObjectModel]>([:])

    public init(modelName: String, inMemory: Bool = false, bundle: Bundle = StorageProvider.modelBundle) throws(StorageError) {
        guard let modelURL = bundle.url(forResource: modelName, withExtension: "momd") else {
            throw .modelNotFound(name: modelName)
        }

        persistentContainer = try Self.models.withLock { models throws(StorageError) -> NSPersistentContainer in
            if let model = models[modelURL] {
                return NSPersistentContainer(name: modelName, managedObjectModel: model)
            }
            guard let model = NSManagedObjectModel(contentsOf: modelURL) else {
                throw .modelNotFound(name: modelName)
            }
            models[modelURL] = model
            return NSPersistentContainer(name: modelName, managedObjectModel: model)
        }

        if inMemory {
            let description = NSPersistentStoreDescription()
            description.type = NSInMemoryStoreType
            persistentContainer.persistentStoreDescriptions = [description]
        }

        // loadPersistentStores calls its completion synchronously for the store
        // types used here, so the error is available by the time it returns.
        var loadError: Error?
        persistentContainer.loadPersistentStores { _, error in
            loadError = error
        }
        if let loadError {
            throw .storeLoadFailed(loadError)
        }

        persistentContainer.viewContext.automaticallyMergesChangesFromParent = true
        persistentContainer.viewContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
    }

    /// Runs `block` on a private background context. Changes are saved only by
    /// calling `context.save()` inside it.
    public func performBackground<T: Sendable>(
        _ block: @escaping @Sendable (NSManagedObjectContext) throws -> T
    ) async throws -> T {
        let context = persistentContainer.newBackgroundContext()
        context.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        return try await context.perform {
            try block(context)
        }
    }

    /// Returns a fresh in-memory store, for tests.
    public static func inMemory(modelName: String, bundle: Bundle = StorageProvider.modelBundle) throws(StorageError) -> StorageProvider {
        try StorageProvider(modelName: modelName, inMemory: true, bundle: bundle)
    }
}
