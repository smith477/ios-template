// Users.swift

/// The feature's entry point.
public enum Users {
    @MainActor
    public static func viewModel(_ dependencies: some UsersDependencies) -> UserViewModel {
        UserViewModel(
            repository: UserDataRepository(
                apiClient: UserAPISessionClient(apiClient: dependencies.apiClient),
                storage: UserCoreDataStorage(storageProvider: dependencies.storageProvider)
            )
        )
    }
}
