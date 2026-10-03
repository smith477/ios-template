// ProductStorageFactory.swift

import AppKit
import Foundation
import Persistence

@testable import Products

/// Returns a fresh in-memory store over the model this feature uses.
func makeStorageProvider() throws(StorageError) -> StorageProvider {
    try .inMemory(storeName: "ProductsTests", modelBundles: [StorageProvider.modelBundle])
}

/// Returns storage over an in-memory store and a throwaway list record.
func makeStorage(
    dateProvider: DateProvider = SystemDateProvider()
) throws(StorageError) -> ProductCoreDataStorage {
    ProductCoreDataStorage(
        storageProvider: try makeStorageProvider(),
        listRecord: ProductListRecord(suiteName: UUID().uuidString),
        dateProvider: dateProvider
    )
}
