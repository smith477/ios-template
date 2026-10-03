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

    /// One merged model per set of bundles for the whole process: separate copies
    /// leave Core Data unable to tell which entity a managed-object class belongs
    /// to. Models stay inside the lock because `NSManagedObjectModel` is not
    /// `Sendable`.
    private static let models = Mutex<[Set<URL>: NSManagedObjectModel]>([:])

    /// Opens the store `storeName` over the merged models of `modelBundles`.
    ///
    /// - Throws: `.modelNotFound` when a bundle holds no model, `.modelConflict`
    ///   when two models define the same entity, `.storeLoadFailed` when the
    ///   store cannot open.
    public init(storeName: String, modelBundles: [Bundle], inMemory: Bool = false) throws(StorageError) {
        let model = try Self.model(merging: modelBundles)
        persistentContainer = NSPersistentContainer(name: storeName, managedObjectModel: model)

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
    public static func inMemory(storeName: String, modelBundles: [Bundle]) throws(StorageError) -> StorageProvider {
        try StorageProvider(storeName: storeName, modelBundles: modelBundles, inMemory: true)
    }

    private static func model(merging bundles: [Bundle]) throws(StorageError) -> NSManagedObjectModel {
        try models.withLock { models throws(StorageError) -> NSManagedObjectModel in
            let key = Set(bundles.map(\.bundleURL))
            if let model = models[key] {
                return model
            }

            // Each bundle's own model must be gone before the merged one is used:
            // while it lives it also claims its entities' classes, and Core Data
            // can no longer tell which entity an `init(context:)` means.
            let model = try autoreleasepool {
                Result { () throws(StorageError) in try merge(bundles) }
            }.get()
            models[key] = model
            return model
        }
    }

    private static func merge(_ bundles: [Bundle]) throws(StorageError) -> NSManagedObjectModel {
        var parts: [NSManagedObjectModel] = []
        for bundle in bundles {
            let urls = bundle.urls(forResourcesWithExtension: "momd", subdirectory: nil) ?? []
            guard !urls.isEmpty else {
                throw .modelNotFound(bundle: bundle.bundleURL.lastPathComponent)
            }
            for url in urls {
                guard let model = NSManagedObjectModel(contentsOf: url) else {
                    throw .modelNotFound(bundle: bundle.bundleURL.lastPathComponent)
                }
                parts.append(model)
            }
        }

        // Merging two entities of one name either drops one silently or raises
        // an Objective-C exception, so a clash is caught here instead.
        var seen: Set<String> = []
        for name in parts.flatMap(\.entities).compactMap(\.name) {
            guard seen.insert(name).inserted else {
                throw .modelConflict(entity: name)
            }
        }

        guard let model = NSManagedObjectModel(byMerging: parts) else {
            fatalError("Core Data could not merge the models of \(bundles.map(\.bundleURL.lastPathComponent))")
        }
        return model
    }
}
