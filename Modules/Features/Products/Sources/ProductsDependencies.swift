// ProductsDependencies.swift

import APIClient
import Persistence

/// What this feature needs from the app in order to run.
///
/// Declaring it here rather than taking loose parameters means the feature
/// documents its own requirements, and adding a platform dependency later
/// changes this protocol and the container that conforms to it — not every
/// call site.
public protocol ProductsDependencies {
    var storageProvider: StorageProvider { get }
    var apiClient: APIClient { get }
}
