// ProductEvent.swift

/// A user action in the Products feature that the app may react to.
///
/// Cases describe what happened, not what should happen next: `sellerTapped`
/// rather than `showUser`. The feature reports; the app decides where that
/// leads. This is what lets Products refer to a seller without depending on
/// the feature that displays one.
public enum ProductEvent: Hashable, Sendable {
    case productTapped(id: Int)
    case sellerTapped(userId: Int)
}
