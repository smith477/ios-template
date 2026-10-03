// Products.swift

import SwiftUI

/// The feature's entry point; its repository, storage and client stay internal.
public enum Products {
    /// The bundle holding this feature's Core Data model, for the app to list in
    /// its store. A resource bundle of its own, so `Bundle.main` will not find it.
    public static var modelBundle: Bundle { .module }

    /// Builds the view model backing `ProductView`.
    ///
    /// - Parameter emit: Receives this feature's events, normally `AppRouter.handle`.
    ///   Required here, because a composed screen that drops its events is a bug.
    @MainActor
    public static func viewModel(
        _ dependencies: some ProductsDependencies,
        emit: @escaping (ProductEvent) -> Void
    ) -> ProductViewModel {
        ProductViewModel(repository: repository(dependencies), emit: emit)
    }

    /// Builds the view for one of this feature's routes.
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
