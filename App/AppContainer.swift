// AppContainer.swift

import APIClient
import Foundation
import Persistence
import Products
import Users

/// Owns the platform dependencies and hands them to features.
///
/// Deliberately not a singleton: tests construct their own container with an
/// in-memory store, which is only possible while this is an ordinary type.
///
/// Each feature declares what it needs as its own protocol and this type
/// conforms to all of them, so adding a platform dependency changes one
/// protocol and this file rather than every call site.
final class AppContainer {
    let storageProvider: StorageProvider
    let apiClient: APIClient

    init(storageProvider: StorageProvider, apiClient: APIClient) {
        self.storageProvider = storageProvider
        self.apiClient = apiClient
    }

    /// The production container.
    ///
    /// A store that cannot be opened is not recoverable at runtime — the app
    /// has no data — so this traps rather than pretending otherwise. Tests use
    /// `init(storageProvider:apiClient:)` with an in-memory store instead.
    static func live() -> AppContainer {
        do {
            return AppContainer(
                storageProvider: try StorageProvider(modelName: "ios_template"),
                apiClient: APIClient(baseURL: URL(string: "https://dummyjson.com")!)
            )
        } catch {
            preconditionFailure("Could not open the Core Data store: \(error)")
        }
    }
}

extension AppContainer: ProductsDependencies {}
extension AppContainer: UsersDependencies {}
