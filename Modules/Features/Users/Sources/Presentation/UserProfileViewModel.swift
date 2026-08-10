// UserProfileViewModel.swift

import Foundation
import Identity

public enum UserProfileState {
    case loading
    case loaded(User)
    case notFound
    case error(Error)
}

@MainActor
@Observable
public final class UserProfileViewModel {
    private let repository: UserRepository
    private let id: Int

    public private(set) var state: UserProfileState = .loading

    public init(repository: UserRepository, id: Int) {
        self.repository = repository
        self.id = id
    }

    public func load() async {
        do {
            let users = try await repository.getUsers()
            if let user = users.first(where: { $0.id == id }) {
                state = .loaded(user)
            } else {
                state = .notFound
            }
        } catch {
            state = .error(error)
        }
    }
}
