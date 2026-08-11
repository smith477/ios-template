// ProductEvent.swift

/// A user action in the Products feature that the app may react to.
///
/// Cases describe what happened, not what should happen next: `sellerTapped`
/// rather than `showUser`. The feature reports; the app decides where it leads.
public enum ProductEvent: Hashable, Sendable {
    case productTapped(id: Int)
    case sellerTapped(userId: Int)
}
