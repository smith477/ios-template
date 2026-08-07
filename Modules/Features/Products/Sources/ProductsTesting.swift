// ProductsTesting.swift

import AppKit
import Foundation
import Persistence

/// Access to the feature's internals for tests.
///
/// The storage and repository types stay internal — the app composes the
/// feature through `Products` and never sees them — but tests need to exercise
/// them directly, and a test target cannot use `@testable` against a framework
/// it links normally.
public enum ProductsTesting {
    /// Storage backed by a throwaway `UserDefaults` suite, so the cache
    /// timestamp of one test never leaks into the next.
    public static func makeStorage(
        storageProvider: StorageProvider,
        dateProvider: DateProvider = SystemDateProvider()
    ) -> any ProductStorage {
        ProductCoreDataStorage(
            storageProvider: storageProvider,
            timestamp: ProductCacheTimestamp(defaults: UserDefaults(suiteName: UUID().uuidString)!),
            dateProvider: dateProvider
        )
    }

    public static func makeRepository(
        apiClient: any ProductApiClient,
        storage: any ProductStorage,
        dateProvider: DateProvider = SystemDateProvider()
    ) -> any ProductRepository {
        ProductDataRepository(apiClient: apiClient, storage: storage, dateProvider: dateProvider)
    }
}
