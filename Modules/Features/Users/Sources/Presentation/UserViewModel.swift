// UserViewModel.swift

import Foundation
import Identity

public enum UserLoadingState {
    case loading, loaded, error(Error)
}

@MainActor
@Observable
public final class UserViewModel {
    private let repository: UserRepository

    public private(set) var users: [User] = []
    public private(set) var loadingState: UserLoadingState = .loading

    public init(repository: UserRepository) {
        self.repository = repository
    }

    public func getUsers() async {
        do {
            users = try await repository.getUsers()
            loadingState = .loaded
        } catch {
            loadingState = .error(error)
        }
    }
}
