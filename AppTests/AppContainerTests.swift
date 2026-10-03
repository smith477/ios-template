// AppContainerTests.swift

// A literal URL that fails to parse should fail the test on the spot.
// swiftlint:disable force_unwrapping

import APIClient
import CoreData
import Foundation
import Persistence
import Products
import Testing

@testable import App

struct AppContainerTests {
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

    /// Separate model copies leave Core Data unable to tell which `ProductEntity`
    /// a fetch means.
    @Test @MainActor
    func storesShareOneModel() throws {
        let first = try StorageProvider.inMemory(modelName: "ios_template")
        let second = try StorageProvider.inMemory(modelName: "ios_template")

        let firstModel = try #require(first.viewContext.persistentStoreCoordinator?.managedObjectModel)
        let secondModel = try #require(second.viewContext.persistentStoreCoordinator?.managedObjectModel)
        #expect(firstModel === secondModel)
    }

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

        // `emit` has no default here, so ignoring events is written out.
        _ = Products.viewModel(stub, emit: { _ in })
    }

    /// Asserts an `https` URL with a host rather than a specific host, so an
    /// adopter's own host still passes.
    @Test @MainActor
    func theAPIBaseURLIsExpandedFromTheBuildSettings() {
        #expect(AppContainer.apiBaseURL.scheme == "https")
        #expect(AppContainer.apiBaseURL.host()?.isEmpty == false)
    }
}
