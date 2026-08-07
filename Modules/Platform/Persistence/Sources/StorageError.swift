// StorageError.swift

import Foundation

/// Errors that can occur during local storage operations.
public enum StorageError: Error, Sendable {
    case notFound
    case modelNotFound(name: String)
    case storeLoadFailed(Error)
    case saveFailed(Error)
    case fetchFailed(Error)
    case deleteFailed(Error)
}

extension StorageError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .notFound:
            return "Record not found"
        case let .modelNotFound(name):
            return "Core Data model '\(name)' is missing from the bundle"
        case let .storeLoadFailed(error):
            return "Failed to open the store: \(error.localizedDescription)"
        case let .saveFailed(error):
            return "Failed to save: \(error.localizedDescription)"
        case let .fetchFailed(error):
            return "Failed to fetch: \(error.localizedDescription)"
        case let .deleteFailed(error):
            return "Failed to delete: \(error.localizedDescription)"
        }
    }
}
