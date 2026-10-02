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
        #if DEBUG
            // UI tests launch against fixtures, so a slow or unavailable API
            // cannot fail them. Compiled out of Release entirely.
            if ProcessInfo.processInfo.arguments.contains(stubNetworkArgument) {
                return stubbed()
            }
        #endif

        do {
            return AppContainer(
                storageProvider: try StorageProvider(modelName: "ios_template"),
                apiClient: APIClient(baseURL: apiBaseURL)
            )
        } catch {
            fatalError("Could not open the Core Data store: \(error)")
        }
    }

    /// The backend for this build configuration: `API_BASE_URL` in
    /// `Project.swift`, expanded into Info.plist at build time. A value that
    /// is missing, or arrives as the unexpanded `$(API_BASE_URL)`, has no
    /// host, so it traps here rather than failing every request later.
    static let apiBaseURL: URL = {
        let value = Bundle.main.object(forInfoDictionaryKey: "APIBaseURL") as? String
        guard let value, let url = URL(string: value), url.scheme != nil, url.host()?.isEmpty == false else {
            fatalError("Info.plist APIBaseURL is missing or malformed: \(value ?? "nil")")
        }
        return url
    }()
}

extension AppContainer: ProductsDependencies {}
extension AppContainer: UsersDependencies {}
