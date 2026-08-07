// AppContainer

import APIClient
import Foundation
import Persistence

@MainActor
public final class AppContainer {
    static let shared = AppContainer()

    // MARK: - Core Dependencies

    private(set) lazy var storageProvider: StorageProvider = .init(modelName: "ios_template")

    private(set) lazy var apiClient: APIClient = .init(baseURL: URL(string: "https://dummyjson.com")!)

    // MARK: - Feature Dependencies

    func makeProductRepository() -> ProductRepository {
        ProductDataRepository(
            apiClient: makeProductAPIClient(),
            storage: makeProductStorage()
        )
    }

    func makeProductAPIClient() -> ProductApiClient {
        ProductAPISessionClient(apiClient: apiClient)
    }

    func makeProductStorage() -> ProductStorage {
        ProductCoreDataStorage(storageProvider: storageProvider)
    }

    func makeProductViewModel() -> ProductViewModel {
        ProductViewModel(repository: makeProductRepository())
    }
}
