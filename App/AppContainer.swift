// AppContainer.swift

import APIClient
import Foundation
import Persistence
import Products

/// Owns the platform dependencies and hands them to features.
///
/// Deliberately not a singleton: tests construct their own container with an
/// in-memory store, which is only possible while this is an ordinary type.
///
/// Each feature declares what it needs as its own protocol and this type
/// conforms to all of them, so adding a platform dependency changes one
/// protocol and this file rather than every call site.
@MainActor
final class AppContainer {
    let storageProvider: StorageProvider
    let apiClient: APIClient

    init(
        storageProvider: StorageProvider = .init(modelName: "ios_template"),
        apiClient: APIClient = .init(baseURL: URL(string: "https://dummyjson.com")!)
    ) {
        self.storageProvider = storageProvider
        self.apiClient = apiClient
    }
}

extension AppContainer: ProductsDependencies {}
