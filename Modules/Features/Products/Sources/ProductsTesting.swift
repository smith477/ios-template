// ProductsTesting.swift

import Foundation
import Persistence

/// Access to the feature's internals for tests.
///
/// The storage and repository types stay internal — the app composes the
/// feature through `Products` and never sees them — but tests need to exercise
/// them directly, and a test target cannot use `@testable` against a framework
/// it links normally.
public enum ProductsTesting {
    public static func makeStorage(storageProvider: StorageProvider) -> any ProductStorage {
        ProductCoreDataStorage(
            storageProvider: storageProvider,
            clock: ProductCacheClock(defaults: UserDefaults(suiteName: UUID().uuidString)!)
        )
    }

    public static func makeRepository(
        apiClient: any ProductApiClient,
        storage: any ProductStorage,
        now: @escaping @Sendable () -> Date = { Date() }
    ) -> any ProductRepository {
        ProductDataRepository(apiClient: apiClient, storage: storage, now: now)
    }
}
