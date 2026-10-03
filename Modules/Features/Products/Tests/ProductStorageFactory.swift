// ProductStorageFactory.swift

import AppKit
import Foundation
import Persistence

@testable import Products

/// Returns storage over an in-memory store and a throwaway list record.
func makeStorage(
    dateProvider: DateProvider = SystemDateProvider()
) throws(StorageError) -> ProductCoreDataStorage {
    ProductCoreDataStorage(
        storageProvider: try .inMemory(modelName: "ios_template"),
        listRecord: ProductListRecord(suiteName: UUID().uuidString),
        dateProvider: dateProvider
    )
}
