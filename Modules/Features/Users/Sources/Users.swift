// Users.swift

import SwiftUI

/// The feature's entry point.
public enum Users {
    /// Builds the view model backing `UserView`.
    ///
    /// - Parameter emit: Receives this feature's events, normally `AppRouter.handle`.
    @MainActor
    public static func viewModel(
        _ dependencies: some UsersDependencies,
        emit: @escaping (UserEvent) -> Void
    ) -> UserViewModel {
        UserViewModel(repository: repository(dependencies), emit: emit)
    }

    /// Builds the view for one of this feature's routes.
    ///
    /// - Parameter emit: Receives this feature's events. No screen emits yet; it is
    ///   taken so one can without changing this signature.
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
