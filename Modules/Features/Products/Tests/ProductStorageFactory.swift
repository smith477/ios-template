//
//  ProductStorageFactory.swift
//  ProductsTests
//

import AppKit
import Foundation
import Persistence

@testable import Products

/// Storage backed by an in-memory store and a throwaway `UserDefaults` suite,
/// so neither the rows nor the cache timestamp of one test reach the next.
func makeStorage(
    dateProvider: DateProvider = SystemDateProvider()
) throws(StorageError) -> ProductCoreDataStorage {
    ProductCoreDataStorage(
        storageProvider: try .inMemory(modelName: "ios_template"),
        timestamp: ProductCacheTimestamp(defaults: UserDefaults(suiteName: UUID().uuidString)!),
        dateProvider: dateProvider
    )
}
