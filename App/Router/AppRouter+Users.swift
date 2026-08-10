// AppRouter+Users.swift

import Users

/// Maps `UserEvent` to navigation.
extension AppRouter {
    /// Routes an event emitted by the Users feature.
    func handle(_ event: UserEvent) {
        switch event {
        case let .userTapped(id):
            push(.user(.profile(id: id)), onto: .users)
        }
    }
}
