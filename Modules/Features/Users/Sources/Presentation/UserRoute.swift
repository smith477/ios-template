// UserRoute.swift

/// A screen the Users feature can show, resolved to a view by
/// `Users.view(_:_:emit:)`.
public enum UserRoute: Hashable, Sendable, Codable {
    case profile(id: Int)
}
