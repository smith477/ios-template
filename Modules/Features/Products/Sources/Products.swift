// Products.swift

/// The feature's entry point.
///
/// The repository, storage and client that back the feature stay internal to
/// this module. The app builds the view model here and composes `ProductView`
/// itself, so navigation and presentation remain the app's decision.
public enum Products {
    @MainActor
    public static func viewModel(_ dependencies: some ProductsDependencies) -> ProductViewModel {
        ProductViewModel(
            repository: ProductDataRepository(
                apiClient: ProductAPISessionClient(apiClient: dependencies.apiClient),
                storage: ProductCoreDataStorage(storageProvider: dependencies.storageProvider)
            )
        )
    }
}
