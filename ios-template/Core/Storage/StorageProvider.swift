// StorageProvider.swift

import CoreData
import Foundation

/// Encapsulates the Core Data stack and provides access to managed object contexts.
///
/// Use `viewContext` for read operations on the main thread.
/// Use `performBackground(_:)` for write operations or heavy reads.
///
/// Example:
/// ```swift
/// let provider = StorageProvider(modelName: "MyApp")
///
/// // Reading on main thread
/// let request = ItemEntity.fetchRequest()
/// let items = try provider.viewContext.fetch(request)
///
/// // Writing on background
/// try await provider.performBackground { context in
///     let entity = ItemEntity(context: context)
///     entity.name = "New Item"
///     try context.save()
/// }
/// ```
public final class StorageProvider: @unchecked Sendable {
    private let persistentContainer: NSPersistentContainer

    /// The main queue context for UI operations.
    /// Only access managed objects fetched from this context on the main thread.
    public var viewContext: NSManagedObjectContext {
        persistentContainer.viewContext
    }

    /// Creates a StorageProvider with the specified model name.
    /// - Parameters:
    ///   - modelName: Name of your .xcdatamodeld file without extension
    ///   - inMemory: When true, uses in-memory store instead of SQLite
    ///   - bundle: Bundle containing the model file
    public init(modelName: String, inMemory: Bool = false, bundle: Bundle = .main) {
        guard let modelURL = bundle.url(forResource: modelName, withExtension: "momd"),
              let model = NSManagedObjectModel(contentsOf: modelURL)
        else {
            fatalError("Failed to load Core Data model: \(modelName)")
        }

        persistentContainer = NSPersistentContainer(name: modelName, managedObjectModel: model)

        if inMemory {
            let description = NSPersistentStoreDescription()
            description.type = NSInMemoryStoreType
            persistentContainer.persistentStoreDescriptions = [description]
        }

        persistentContainer.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Failed to load persistent stores: \(error)")
            }
        }

        persistentContainer.viewContext.automaticallyMergesChangesFromParent = true
        persistentContainer.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    /// Executes a closure on a private background context.
    ///
    /// Use this method for write operations or expensive reads to avoid blocking the main thread.
    /// The closure executes synchronously on the context's private queue.
    /// Changes are not automatically saved - call `context.save()` within the closure.
    ///
    /// - Parameter block: A closure that receives the background context and returns a value.
    /// - Returns: The value returned by the closure.
    /// - Throws: Rethrows any error thrown by the closure.
    public func performBackground<T: Sendable>(
        _ block: @escaping (NSManagedObjectContext) throws -> T
    ) async throws -> T {
        let context = persistentContainer.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return try await context.perform {
            try block(context)
        }
    }

    /// Creates an in-memory StorageProvider for unit testing.
    /// Each call creates a fresh, isolated store.
    public static func inMemory(modelName: String, bundle: Bundle = .main) -> StorageProvider {
        StorageProvider(modelName: modelName, inMemory: true, bundle: bundle)
    }
}
