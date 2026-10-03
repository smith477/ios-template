// StorageProviderTests.swift

import CoreData
import Foundation
import Testing

@testable import Persistence

struct StorageProviderTests {
    private struct Failure: Error, Equatable {}

    @Test
    func inMemoryOpensAnInMemoryStore() throws {
        let provider = try StorageProvider.inMemory(modelName: "ios_template")

        let store = try #require(provider.viewContext.persistentStoreCoordinator?.persistentStores.first)
        #expect(store.type == NSInMemoryStoreType)
    }

    @Test
    func aMissingModelThrowsModelNotFound() {
        let error = #expect(throws: StorageError.self) {
            try StorageProvider.inMemory(modelName: "NoSuchModel")
        }

        guard case let .modelNotFound(name) = error else {
            Issue.record("Expected .modelNotFound, got \(String(describing: error))")
            return
        }
        #expect(name == "NoSuchModel")
    }

    @Test
    func performBackgroundReturnsTheBlocksValue() async throws {
        let provider = try StorageProvider.inMemory(modelName: "ios_template")

        let value = try await provider.performBackground { _ in 42 }

        #expect(value == 42)
    }

    @Test
    func performBackgroundRethrowsTheBlocksError() async throws {
        let provider = try StorageProvider.inMemory(modelName: "ios_template")

        await #expect(throws: Failure()) {
            try await provider.performBackground { _ -> Int in throw Failure() }
        }
    }
}
