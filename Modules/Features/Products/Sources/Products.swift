// Products.swift

import SwiftUI

/// The feature's entry point. The repository, storage and client backing it
/// stay internal to this module.
public enum Products {
    /// Builds the view model backing `ProductView`.
    ///
    /// - Parameter emit: Receives this feature's events, normally
    ///   `AppRouter.handle`. Required here, unlike on the view model
    ///   initialisers, because a composed screen that drops its events is a bug.
    @MainActor
    public static func viewModel(
        _ dependencies: some ProductsDependencies,
        emit: @escaping (ProductEvent) -> Void
    ) -> ProductViewModel {
        ProductViewModel(repository: repository(dependencies), emit: emit)
    }

    /// Turns a route back into a screen without exposing the repository.
    @MainActor
    public static func view(
        _ route: ProductRoute,
        _ dependencies: some ProductsDependencies,
        emit: @escaping (ProductEvent) -> Void
    ) -> some View {
        switch route {
        case let .detail(id):
            ProductDetailView(
                viewModel: ProductDetailViewModel(
                    repository: repository(dependencies),
                    id: id,
                    emit: emit
                )
            )
        }
    }

    private static func repository(_ dependencies: some ProductsDependencies) -> ProductRepository {
        ProductDataRepository(
            apiClient: ProductAPISessionClient(apiClient: dependencies.apiClient),
            storage: ProductCoreDataStorage(storageProvider: dependencies.storageProvider)
        )
    }
}
