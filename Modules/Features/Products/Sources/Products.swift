// Products.swift

import SwiftUI

/// The feature's entry point.
///
/// The repository, storage and client that back the feature stay internal to
/// this module. The app builds the view model here and composes `ProductView`
/// itself, so navigation and presentation remain the app's decision.
public enum Products {
    /// Builds the view model backing `ProductView`.
    ///
    /// - Parameters:
    ///   - dependencies: Platform services this feature needs.
    ///   - emit: Receives this feature's events, normally `AppRouter.handle`.
    ///     Required here — unlike on the view model initialisers, which
    ///     default it for previews — because a composed screen that silently
    ///     drops its events is a bug.
    @MainActor
    public static func viewModel(
        _ dependencies: some ProductsDependencies,
        emit: @escaping (ProductEvent) -> Void
    ) -> ProductViewModel {
        ProductViewModel(repository: repository(dependencies), emit: emit)
    }

    /// Builds the view for one of this feature's routes.
    ///
    /// The app owns the navigation stack and registers the destination; this
    /// turns a route back into a screen without exposing the repository or the
    /// view model's dependencies.
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
