// User.swift

import Foundation

/// A person, as this feature shows them.
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
