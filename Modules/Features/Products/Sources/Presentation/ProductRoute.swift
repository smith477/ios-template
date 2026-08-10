// ProductRoute.swift

/// A screen the Products feature can show.
///
/// Cases carry ids rather than models or view models, which keeps `Hashable`
/// and `Codable` derivable and leaves the type free of imports. `Codable` is
/// declared ahead of need: state restoration and deep linking both require
/// encoding a stack, and retrofitting the conformance later would touch every
/// feature.
///
/// Resolve a route to a view with `Products.view(_:_:emit:)`.
public enum ProductRoute: Hashable, Sendable, Codable {
    case detail(id: Int)
}
