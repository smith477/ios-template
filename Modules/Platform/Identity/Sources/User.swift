// User.swift

import Foundation

/// A person, as more than one feature understands them.
///
/// This type started inside the Users feature and moved here when Products
/// needed it too. That is the admission rule for this module and every other
/// module under Platform: a type moves out when a *second* feature already
/// needs it, never in anticipation. Value types only — no services, no
/// networking, no persistence.
///
/// The module is named Identity rather than Shared or Common because a name
/// that describes its contents is the thing that keeps unrelated types from
/// accumulating in it.
public struct User: Identifiable, Sendable, Hashable {
    public let id: Int
    public let firstName: String
    public let lastName: String
    public let email: String
    public let image: String

    public init(id: Int, firstName: String, lastName: String, email: String, image: String) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
        self.image = image
    }

    public var fullName: String { "\(firstName) \(lastName)" }
}
