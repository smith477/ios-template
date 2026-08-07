// UsersDependencies.swift

import APIClient
import Persistence

/// What this feature needs from the app in order to run.
public protocol UsersDependencies {
    var storageProvider: StorageProvider { get }
    var apiClient: APIClient { get }
}
