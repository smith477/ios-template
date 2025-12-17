// ProductEntity.swift

import CoreData
import Foundation

// MARK: - ProductEntity

@objc(ProductEntity)
public class ProductEntity: NSManagedObject {
    @NSManaged public var id: Int32
    @NSManaged public var title: String
    @NSManaged public var productDescription: String?
    @NSManaged public var category: String?
    @NSManaged public var price: Float
    @NSManaged public var brand: String?
    @NSManaged public var thumbnail: String?
    @NSManaged public var images: Set<ProductImagesEntity>
    @NSManaged public var meta: MetaEntity?
    @NSManaged public var tags: Set<ProductTagsEntity>
}

public extension ProductEntity {
    @nonobjc class func fetchRequest() -> NSFetchRequest<ProductEntity> {
        NSFetchRequest<ProductEntity>(entityName: "ProductEntity")
    }
}

extension ProductEntity {
    @objc(addImagesObject:)
    @NSManaged func addToImages(_ value: ProductImagesEntity)

    @objc(removeImagesObject:)
    @NSManaged func removeFromImages(_ value: ProductImagesEntity)

    @objc(addImages:)
    @NSManaged func addToImages(_ values: NSSet)

    @objc(removeImages:)
    @NSManaged func removeFromImages(_ values: NSSet)

    @objc(addTagsObject:)
    @NSManaged func addToTags(_ value: ProductTagsEntity)

    @objc(removeTagsObject:)
    @NSManaged func removeFromTags(_ value: ProductTagsEntity)

    @objc(addTags:)
    @NSManaged func addToTags(_ values: NSSet)

    @objc(removeTags:)
    @NSManaged func removeFromTags(_ values: NSSet)
}

extension ProductEntity {
    func toDomain() -> Product {
        Product(
            id: Int(id),
            title: title,
            description: productDescription ?? "",
            category: category ?? "",
            price: Double(price),
            tags: tags.compactMap { $0.tag },
            brand: brand ?? "",
            meta: meta?.toDomain() ?? Meta(createdAt: Date(), updatedAt: Date()),
            thumbnail: thumbnail ?? "",
            images: images.compactMap { $0.image }
        )
    }

    func update(from product: Product, in context: NSManagedObjectContext) {
        id = Int32(product.id)
        title = product.title
        productDescription = product.description
        category = product.category
        price = Float(product.price)
        brand = product.brand
        thumbnail = product.thumbnail

        images.forEach { context.delete($0) }
        tags.forEach { context.delete($0) }
        if let existingMeta = meta {
            context.delete(existingMeta)
        }

        for imageUrl in product.images {
            let imageEntity = ProductImagesEntity(context: context)
            imageEntity.image = imageUrl
            imageEntity.product = self
            addToImages(imageEntity)
        }

        for tag in product.tags {
            let tagEntity = ProductTagsEntity(context: context)
            tagEntity.tag = tag
            tagEntity.product = self
            addToTags(tagEntity)
        }

        let metaEntity = MetaEntity(context: context)
        metaEntity.createdAt = product.meta.createdAt
        metaEntity.updatedAt = product.meta.updatedAt
        metaEntity.product = self
        meta = metaEntity
    }

    convenience init(product: Product, context: NSManagedObjectContext) {
        self.init(context: context)
        update(from: product, in: context)
    }
}

// MARK: - MetaEntity

@objc(MetaEntity)
public class MetaEntity: NSManagedObject {
    @NSManaged public var createdAt: Date?
    @NSManaged public var updatedAt: Date?
    @NSManaged public var product: ProductEntity?
}

extension MetaEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<MetaEntity> {
        NSFetchRequest<MetaEntity>(entityName: "MetaEntity")
    }

    func toDomain() -> Meta {
        Meta(createdAt: createdAt ?? Date(), updatedAt: updatedAt ?? Date())
    }
}

// MARK: - ProductImagesEntity

@objc(ProductImagesEntity)
public class ProductImagesEntity: NSManagedObject {
    @NSManaged public var image: String?
    @NSManaged public var product: ProductEntity?
}

public extension ProductImagesEntity {
    @nonobjc class func fetchRequest() -> NSFetchRequest<ProductImagesEntity> {
        NSFetchRequest<ProductImagesEntity>(entityName: "ProductImagesEntity")
    }
}

// MARK: - ProductTagsEntity

@objc(ProductTagsEntity)
public class ProductTagsEntity: NSManagedObject {
    @NSManaged public var tag: String?
    @NSManaged public var product: ProductEntity?
}

public extension ProductTagsEntity {
    @nonobjc class func fetchRequest() -> NSFetchRequest<ProductTagsEntity> {
        NSFetchRequest<ProductTagsEntity>(entityName: "ProductTagsEntity")
    }
}
