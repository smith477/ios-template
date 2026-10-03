// UsersDependencies.swift

import APIClient
import Persistence

/// The services this feature needs from the app.
public protocol UsersDependencies {
    var storageProvider: StorageProvider { get }
    var apiClient: APIClient { get }
}
