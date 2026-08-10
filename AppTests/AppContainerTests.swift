//
//  AppContainerTests.swift
//  AppTests
//

import APIClient
import CoreData
import Foundation
import Persistence
import Products
import Testing
@testable import App

struct AppContainerTests {
    /// The container is injectable: a test can hand it an in-memory store
    /// instead of touching the on-disk one. This is the reason it is not a
    /// singleton.
    @Test @MainActor
    func usesTheStoreItIsGiven() throws {
        let container = AppContainer(
            storageProvider: try .inMemory(modelName: "ios_template"),
            apiClient: APIClient(baseURL: URL(string: "https://example.invalid")!)
        )

        let store = try #require(
            container.storageProvider.viewContext.persistentStoreCoordinator?.persistentStores.first
        )
        #expect(store.type == NSInMemoryStoreType)
    }

    /// A feature is satisfied by anything meeting its own protocol, so a test
    /// builds only what that feature needs rather than the whole container.
    @Test @MainActor
    func featureAcceptsATestDouble() throws {
        struct Stub: ProductsDependencies {
            let storageProvider: StorageProvider
            let apiClient: APIClient
        }

        let stub = Stub(
            storageProvider: try .inMemory(modelName: "ios_template"),
            apiClient: APIClient(baseURL: URL(string: "https://example.invalid")!)
        )

        // This test is about the dependency seam, not navigation, so events
        // go nowhere. `emit` has no default at this entry point precisely so
        // that ignoring them has to be written down.
        _ = Products.viewModel(stub, emit: { _ in })
    }
}
