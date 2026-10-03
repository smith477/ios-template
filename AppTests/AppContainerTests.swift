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
            storageProvider: try .inMemory(storeName: AppContainer.storeName, modelBundles: AppContainer.modelBundles),
            apiClient: APIClient(baseURL: URL(string: "https://example.invalid")!)
        )

        let store = try #require(
            container.storageProvider.viewContext.persistentStoreCoordinator?.persistentStores.first
        )
        #expect(store.type == NSInMemoryStoreType)
    }

    @Test @MainActor
    func featureAcceptsATestDouble() throws {
        struct Stub: ProductsDependencies {
            let storageProvider: StorageProvider
            let apiClient: APIClient
        }

        let stub = Stub(
            storageProvider: try .inMemory(storeName: AppContainer.storeName, modelBundles: AppContainer.modelBundles),
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
