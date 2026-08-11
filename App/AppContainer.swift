// AppContainer.swift

import APIClient
import Foundation
import Persistence
import Products
import Users

/// Owns the platform dependencies and hands them to features.
///
/// Deliberately not a singleton: tests construct their own container with an
/// in-memory store. Each feature declares what it needs as its own protocol,
/// and this type conforms to all of them.
final class AppContainer {
    let storageProvider: StorageProvider
    let apiClient: APIClient

    init(storageProvider: StorageProvider, apiClient: APIClient) {
        self.storageProvider = storageProvider
        self.apiClient = apiClient
    }

    /// The production container. A store that cannot be opened leaves the app
    /// with no data, so this traps rather than pretending otherwise.
    static func live() -> AppContainer {
        do {
            return AppContainer(
                storageProvider: try StorageProvider(modelName: "ios_template"),
                // swiftlint:disable:next force_unwrapping - a literal URL that parses or the build is broken
                apiClient: APIClient(baseURL: URL(string: "https://dummyjson.com")!)
            )
        } catch {
            preconditionFailure("Could not open the Core Data store: \(error)")
        }
    }
}

extension AppContainer: ProductsDependencies {}
extension AppContainer: UsersDependencies {}
