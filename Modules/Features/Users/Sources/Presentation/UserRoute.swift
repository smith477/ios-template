// UserRoute.swift

/// A screen the Users feature can show.
///
/// Cases carry ids; see `ProductRoute`. Resolve a route to a view with
/// `Users.view(_:_:emit:)`.
public enum UserRoute: Hashable, Sendable, Codable {
    case profile(id: Int)
}
