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
    @NSManaged public var price: NSDecimalNumber
    @NSManaged public var brand: String?
    @NSManaged public var thumbnail: String?
    @NSManaged public var images: Set<ProductImagesEntity>
    @NSManaged public var meta: MetaEntity?
    @NSManaged public var tags: Set<ProductTagsEntity>
}

public extension ProductEntity {
    @nonobjc
    class func fetchRequest() -> NSFetchRequest<ProductEntity> {
        NSFetchRequest<ProductEntity>(entityName: "ProductEntity")
    }
}

extension ProductEntity {
    @objc(addImagesObject:)
    @NSManaged
    func addToImages(_ value: ProductImagesEntity)

    @objc(removeImagesObject:)
    @NSManaged
    func removeFromImages(_ value: ProductImagesEntity)

    @objc(addImages:)
    @NSManaged
    func addToImages(_ values: NSSet)

    @objc(removeImages:)
    @NSManaged
    func removeFromImages(_ values: NSSet)

    @objc(addTagsObject:)
    @NSManaged
    func addToTags(_ value: ProductTagsEntity)

    @objc(removeTagsObject:)
    @NSManaged
    func removeFromTags(_ value: ProductTagsEntity)

    @objc(addTags:)
    @NSManaged
    func addToTags(_ values: NSSet)

    @objc(removeTags:)
    @NSManaged
    func removeFromTags(_ values: NSSet)
}

extension ProductEntity {
    func toDomain() -> Product {
        Product(
            id: Int(id),
            title: title,
            description: productDescription ?? "",
            category: category ?? "",
            price: price as Decimal,
            tags: tags.compactMap(\.tag),
            brand: brand ?? "",
            meta: meta?.toDomain() ?? Meta(createdAt: Date(), updatedAt: Date()),
            thumbnail: thumbnail ?? "",
            images: images.compactMap(\.image)
        )
    }

    func update(from product: Product, in context: NSManagedObjectContext) {
        id = Int32(product.id)
        title = product.title
        productDescription = product.description
        category = product.category
        price = product.price as NSDecimalNumber
        brand = product.brand
        thumbnail = product.thumbnail

        // Only the rows that actually changed are touched. Deleting every child
        // and recreating it churns the store on each refresh, and leaves a
        // window where a product has no images.
        syncImages(product.images, in: context)
        syncTags(product.tags, in: context)

        let metaEntity = meta ?? MetaEntity(context: context)
        metaEntity.createdAt = product.meta.createdAt
        metaEntity.updatedAt = product.meta.updatedAt
        metaEntity.product = self
        meta = metaEntity
    }

    private func syncImages(_ urls: [String], in context: NSManagedObjectContext) {
        let wanted = Set(urls)
        let existing = Dictionary(
            images.compactMap { entity in entity.image.map { ($0, entity) } },
            uniquingKeysWith: { first, _ in first }
        )

        for (url, entity) in existing where !wanted.contains(url) {
            context.delete(entity)
        }
        for url in wanted where existing[url] == nil {
            let entity = ProductImagesEntity(context: context)
            entity.image = url
            entity.product = self
            addToImages(entity)
        }
    }

    private func syncTags(_ names: [String], in context: NSManagedObjectContext) {
        let wanted = Set(names)
        let existing = Dictionary(
            tags.compactMap { entity in entity.tag.map { ($0, entity) } },
            uniquingKeysWith: { first, _ in first }
        )

        for (name, entity) in existing where !wanted.contains(name) {
            context.delete(entity)
        }
        for name in wanted where existing[name] == nil {
            let entity = ProductTagsEntity(context: context)
            entity.tag = name
            entity.product = self
            addToTags(entity)
        }
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
    @nonobjc
    public class func fetchRequest() -> NSFetchRequest<MetaEntity> {
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
    @nonobjc
    class func fetchRequest() -> NSFetchRequest<ProductImagesEntity> {
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
    @nonobjc
    class func fetchRequest() -> NSFetchRequest<ProductTagsEntity> {
        NSFetchRequest<ProductTagsEntity>(entityName: "ProductTagsEntity")
    }
}
