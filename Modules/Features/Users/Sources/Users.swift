// Users.swift

import SwiftUI

/// The feature's entry point.
public enum Users {
    /// Builds the view model backing `UserView`.
    ///
    /// - Parameters:
    ///   - dependencies: Platform services this feature needs.
    ///   - emit: Receives this feature's events, normally `AppRouter.handle`.
    @MainActor
    public static func viewModel(
        _ dependencies: some UsersDependencies,
        emit: @escaping (UserEvent) -> Void
    ) -> UserViewModel {
        UserViewModel(repository: repository(dependencies), emit: emit)
    }

    /// Builds the view for one of this feature's routes.
    ///
    /// - Parameter emit: Unused by the screens that exist today, and taken
    ///   anyway so that adding one that emits does not change this signature.
    @MainActor
    public static func view(
        _ route: UserRoute,
        _ dependencies: some UsersDependencies,
        emit: @escaping (UserEvent) -> Void
    ) -> some View {
        switch route {
        case let .profile(id):
            UserProfileView(
                viewModel: UserProfileViewModel(repository: repository(dependencies), id: id)
            )
        }
    }

    private static func repository(_ dependencies: some UsersDependencies) -> UserRepository {
        UserDataRepository(
            apiClient: UserAPISessionClient(apiClient: dependencies.apiClient),
            storage: UserCoreDataStorage(storageProvider: dependencies.storageProvider)
        )
    }
}
