// ProductRoute.swift

/// A screen the Products feature can show, resolved to a view by
/// `Products.view(_:_:emit:)`. Cases carry ids rather than models, so the
/// conformances stay derivable.
public enum ProductRoute: Hashable, Sendable, Codable {
    case detail(id: Int)
}
