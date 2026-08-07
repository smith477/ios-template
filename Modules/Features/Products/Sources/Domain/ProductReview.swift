// ProductReview.swift

import Foundation
import Identity

/// A review left on a product.
///
/// The reviewer is an `Identity.User` rather than a type of this feature's
/// own: Products and Users both need to describe the same person, which is
/// what moved `User` out into Platform. Neither feature imports the other.
public struct ProductReview: Identifiable, Sendable {
    public let id: Int
    public let rating: Int
    public let comment: String
    public let reviewer: User

    public init(id: Int, rating: Int, comment: String, reviewer: User) {
        self.id = id
        self.rating = rating
        self.comment = comment
        self.reviewer = reviewer
    }
}
