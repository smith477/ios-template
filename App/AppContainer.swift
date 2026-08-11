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

    /// The production container. Both failures here leave the app with nothing
    /// to show, so each traps with the reason rather than pretending otherwise.
    static func live() -> AppContainer {
        guard let baseURL = URL(string: baseURLString) else {
            fatalError("Malformed API base URL: \(baseURLString)")
        }

        do {
            return AppContainer(
                storageProvider: try StorageProvider(modelName: "ios_template"),
                apiClient: APIClient(baseURL: baseURL)
            )
        } catch {
            fatalError("Could not open the Core Data store: \(error)")
        }
    }

    private static let baseURLString = "https://dummyjson.com"
}

extension AppContainer: ProductsDependencies {}
extension AppContainer: UsersDependencies {}
