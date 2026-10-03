// AppRouter+Users.swift

import Users

/// Maps `UserEvent` to navigation.
extension AppRouter {
    func handle(_ event: UserEvent) {
        switch event {
        case let .userTapped(id):
            push(.user(.profile(id: id)), onto: .users)
        }
    }
}
