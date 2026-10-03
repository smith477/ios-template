// ProductsDependencies.swift

import APIClient
import Persistence

/// The services this feature needs from the app. Adding one changes this
/// protocol and the container, not every call site.
public protocol ProductsDependencies {
    var storageProvider: StorageProvider { get }
    var apiClient: APIClient { get }
}
