// UserResponse.swift

import Foundation
import Identity

struct UsersResponse: Decodable {
    let users: [UserResponse]
}

struct UserResponse: Decodable {
    let id: Int
    let firstName: String
    let lastName: String
    let email: String
    let image: String
}

extension UserResponse {
    func toDomain() -> User {
        User(
            id: id,
            firstName: firstName,
            lastName: lastName,
            email: email,
            image: image
        )
    }
}
