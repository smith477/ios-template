// ProductRoute.swift

/// A screen the Products feature can show, resolved to a view by
/// `Products.view(_:_:emit:)`.
///
/// Cases carry ids rather than models, which keeps the conformances derivable
/// and the type free of imports.
public enum ProductRoute: Hashable, Sendable, Codable {
    case detail(id: Int)
}
