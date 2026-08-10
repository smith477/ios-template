// UserEntity.swift

import CoreData
import Foundation
import Identity

@objc(UserEntity)
final class UserEntity: NSManagedObject {
    @NSManaged var id: Int32
    @NSManaged var firstName: String?
    @NSManaged var lastName: String?
    @NSManaged var email: String?
    @NSManaged var image: String?
}

extension UserEntity {
    @nonobjc
    class func fetchRequest() -> NSFetchRequest<UserEntity> {
        NSFetchRequest<UserEntity>(entityName: "UserEntity")
    }

    func toDomain() -> User {
        User(
            id: Int(id),
            firstName: firstName ?? "",
            lastName: lastName ?? "",
            email: email ?? "",
            image: image ?? ""
        )
    }

    func update(from user: User) {
        id = Int32(user.id)
        firstName = user.firstName
        lastName = user.lastName
        email = user.email
        image = user.image
    }
}
