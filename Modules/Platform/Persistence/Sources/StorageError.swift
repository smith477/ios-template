// StorageError.swift

import Foundation

/// An error from a local storage operation.
public enum StorageError: Error, Sendable {
    case notFound
    case modelNotFound(bundle: String)
    case modelConflict(entity: String)
    case conflictingBundleLists(shared: [String])
    case storeLoadFailed(Error)
    case saveFailed(Error)
    case fetchFailed(Error)
    case deleteFailed(Error)
}

extension StorageError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .notFound:
            "Record not found"
        case let .modelNotFound(bundle):
            "No Core Data model in bundle '\(bundle)'"
        case let .modelConflict(entity):
            "Two Core Data models define the entity '\(entity)'"
        case let .conflictingBundleLists(shared):
            "Bundles \(shared) are already merged into a model from a different list"
        case let .storeLoadFailed(error):
            "Failed to open the store: \(error.localizedDescription)"
        case let .saveFailed(error):
            "Failed to save: \(error.localizedDescription)"
        case let .fetchFailed(error):
            "Failed to fetch: \(error.localizedDescription)"
        case let .deleteFailed(error):
            "Failed to delete: \(error.localizedDescription)"
        }
    }
}
