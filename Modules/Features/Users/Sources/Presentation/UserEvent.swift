// UserEvent.swift

/// A user action in the Users feature that the app may react to.
///
/// Cases describe what happened, not what should happen next. See
/// `ProductEvent`.
public enum UserEvent: Hashable, Sendable {
    case userTapped(id: Int)
}
