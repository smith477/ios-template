// StorageProviderTests.swift

import CoreData
import Foundation
import Testing

@testable import Persistence

struct StorageProviderTests {
    private struct Failure: Error, Equatable {}

    @Test
    func inMemoryOpensAnInMemoryStore() throws {
        let scratch = try Scratch()
        defer { scratch.remove() }

        let provider = try StorageProvider.inMemory(storeName: "Test", modelBundles: [scratch.bundle(holding: ["First"])])

        let store = try #require(provider.viewContext.persistentStoreCoordinator?.persistentStores.first)
        #expect(store.type == NSInMemoryStoreType)
    }

    @Test
    func modelsFromTwoBundlesMergeIntoOneStore() throws {
        let scratch = try Scratch()
        defer { scratch.remove() }

        let provider = try StorageProvider.inMemory(
            storeName: "Test",
            modelBundles: [scratch.bundle(holding: ["First"]), scratch.bundle(holding: ["Second"])]
        )

        let model = try #require(provider.viewContext.persistentStoreCoordinator?.managedObjectModel)
        #expect(Set(model.entitiesByName.keys) == ["FirstEntity", "SecondEntity"])
    }

    @Test
    func aBundleWithoutAModelThrowsModelNotFound() throws {
        let scratch = try Scratch()
        defer { scratch.remove() }

        let empty = try scratch.bundle(holding: [])

        let error = #expect(throws: StorageError.self) {
            try StorageProvider.inMemory(storeName: "Test", modelBundles: [empty])
        }

        guard case let .modelNotFound(name) = error else {
            Issue.record("Expected .modelNotFound, got \(String(describing: error))")
            return
        }
        #expect(name == empty.bundleURL.lastPathComponent)
    }

    @Test
    func aModelThatWillNotLoadThrowsModelUnreadable() throws {
        let scratch = try Scratch()
        defer { scratch.remove() }

        let bundle = try scratch.bundle(holding: [])
        let broken = bundle.bundleURL.appending(path: "Broken.momd")
        try FileManager.default.createDirectory(at: broken, withIntermediateDirectories: true)
        try Data("not a model".utf8).write(to: broken.appending(path: "Broken.mom"))

        let error = #expect(throws: StorageError.self) {
            try StorageProvider.inMemory(storeName: "Test", modelBundles: [bundle])
        }

        guard case let .modelUnreadable(model, _) = error else {
            Issue.record("Expected .modelUnreadable, got \(String(describing: error))")
            return
        }
        #expect(model == "Broken.momd")
    }

    @Test
    func anEntityDefinedInTwoModelsThrowsModelConflict() throws {
        let scratch = try Scratch()
        defer { scratch.remove() }

        let bundles = try [scratch.bundle(holding: ["First"]), scratch.bundle(holding: ["First"])]

        let error = #expect(throws: StorageError.self) {
            try StorageProvider.inMemory(storeName: "Test", modelBundles: bundles)
        }

        guard case let .modelConflict(entity) = error else {
            Issue.record("Expected .modelConflict, got \(String(describing: error))")
            return
        }
        #expect(entity == "FirstEntity")
    }

    /// Separate model copies leave Core Data unable to tell which entity a
    /// managed-object class belongs to.
    @Test
    func storesOverTheSameBundlesShareOneModel() throws {
        let scratch = try Scratch()
        defer { scratch.remove() }

        let first = try scratch.bundle(holding: ["First"])
        let second = try scratch.bundle(holding: ["Second"])

        let one = try StorageProvider.inMemory(storeName: "Test", modelBundles: [first, second])
        let other = try StorageProvider.inMemory(storeName: "Test", modelBundles: [second, first])

        let oneModel = try #require(one.viewContext.persistentStoreCoordinator?.managedObjectModel)
        let otherModel = try #require(other.viewContext.persistentStoreCoordinator?.managedObjectModel)
        #expect(oneModel === otherModel)
    }

    @Test
    func performBackgroundReturnsTheBlocksValue() async throws {
        let scratch = try Scratch()
        defer { scratch.remove() }

        let provider = try StorageProvider.inMemory(storeName: "Test", modelBundles: [scratch.bundle(holding: ["First"])])

        let value = try await provider.performBackground { _ in 42 }

        #expect(value == 42)
    }

    @Test
    func performBackgroundRethrowsTheBlocksError() async throws {
        let scratch = try Scratch()
        defer { scratch.remove() }

        let provider = try StorageProvider.inMemory(storeName: "Test", modelBundles: [scratch.bundle(holding: ["First"])])

        await #expect(throws: Failure()) {
            try await provider.performBackground { _ -> Int in throw Failure() }
        }
    }

    /// Throwaway bundles for one test, each holding copies of the named test
    /// models, so no test shares another's cached model by accident. Removed when
    /// the test ends: nothing asks the model cache for their paths again.
    private struct Scratch {
        let root = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)

        init() throws {
            try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        }

        func bundle(holding models: [String]) throws -> Bundle {
            let directory = root.appending(path: UUID().uuidString)
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            for name in models {
                let source = try #require(Bundle.module.url(forResource: name, withExtension: "momd"))
                try FileManager.default.copyItem(at: source, to: directory.appending(path: "\(name).momd"))
            }
            return try #require(Bundle(url: directory))
        }

        func remove() {
            try? FileManager.default.removeItem(at: root)
        }
    }
}
