// AppContainer.swift

import APIClient
import Foundation
import Persistence
import Products
import Users

/// Owns the platform dependencies and hands them to features.
///
/// Not a singleton, so a test can build one over an in-memory store.
final class AppContainer {
    let storageProvider: StorageProvider
    let apiClient: APIClient

    init(storageProvider: StorageProvider, apiClient: APIClient) {
        self.storageProvider = storageProvider
        self.apiClient = apiClient
    }

    /// The store's file name. Neutral, so a renamed app leaves nothing of the
    /// template behind.
    static let storeName = "App"

    /// Every feature's Core Data model, merged into the one store.
    static let modelBundles: [Bundle] = [StorageProvider.modelBundle]

    /// The production container. Traps if the store cannot open, since the app
    /// has nothing to show without it.
    static func live() -> AppContainer {
        #if DEBUG
            // UI tests run against fixtures. Compiled out of Release.
            if ProcessInfo.processInfo.arguments.contains(stubNetworkArgument) {
                return stubbed()
            }
        #endif

        do {
            return AppContainer(
                storageProvider: try StorageProvider(storeName: storeName, modelBundles: modelBundles),
                apiClient: APIClient(baseURL: apiBaseURL)
            )
        } catch {
            fatalError("Could not open the Core Data store: \(error)")
        }
    }

    /// The backend for this build, from Info.plist's `APIBaseURL`. Traps on a
    /// missing or unexpanded value rather than failing every request later.
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
