// ProductReview.swift

import Foundation
import Identity

/// A review left on a product. The reviewer is `Identity.User`, the type the
/// Users feature shares.
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
