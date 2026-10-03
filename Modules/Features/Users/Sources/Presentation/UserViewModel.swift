// UserViewModel.swift

import Foundation

public enum UserLoadingState {
    case loading, loaded, error(Error)
}

@MainActor
@Observable
public final class UserViewModel {
    private let repository: UserRepository
    private let emit: (UserEvent) -> Void

    public private(set) var users: [User] = []
    public private(set) var loadingState: UserLoadingState = .loading

    /// Creates a view model over `repository`.
    ///
    /// - Parameter emit: Receives user actions; discarded by default, for previews
    ///   and tests.
    public init(
        repository: UserRepository,
        emit: @escaping (UserEvent) -> Void = { _ in }
    ) {
        self.repository = repository
        self.emit = emit
    }

    public func didTapUser(id: Int) {
        emit(.userTapped(id: id))
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
