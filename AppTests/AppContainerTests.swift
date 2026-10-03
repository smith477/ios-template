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

    /// Asserts against what each listed bundle was compiled with, not a list of
    /// entity names, so it still holds once an adopter's own features replace these.
    @Test @MainActor
    func theStoreHoldsEveryEntityOfEveryListedModel() throws {
        let provider = try StorageProvider.inMemory(
            storeName: AppContainer.storeName,
            modelBundles: AppContainer.modelBundles
        )

        let model = try #require(provider.viewContext.persistentStoreCoordinator?.managedObjectModel)
        let compiled = try compiledEntityHashes(in: AppContainer.modelBundles)
        #expect(!compiled.isEmpty)
        #expect(model.entityVersionHashesByName == compiled)
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

    /// Each entity's version hash as compiled into the bundles, read from the
    /// models' metadata: loading a second copy of a model would leave two
    /// descriptions claiming one class while other tests insert rows.
    private func compiledEntityHashes(in bundles: [Bundle]) throws -> [String: Data] {
        var hashes: [String: Data] = [:]
        for bundle in bundles {
            for url in bundle.urls(forResourcesWithExtension: "momd", subdirectory: nil) ?? [] {
                let info = try #require(NSDictionary(contentsOf: url.appending(path: "VersionInfo.plist")))
                let current = try #require(info["NSManagedObjectModel_CurrentVersionName"] as? String)
                let versions = try #require(info["NSManagedObjectModel_VersionHashes"] as? [String: [String: Data]])
                hashes.merge(try #require(versions[current]), uniquingKeysWith: { first, _ in first })
            }
        }
        return hashes
    }
}
