// StubFixtures.swift

#if DEBUG
    /// The responses `StubURLProtocol` serves, trimmed from real dummyjson.com
    /// payloads so they decode through the same response types the live API does.
    ///
    /// Swift strings rather than bundled JSON files, so `#if DEBUG` keeps them out
    /// of a Release build with no resource rules to maintain. Names are stable and
    /// recognisable, for UI tests to assert exact text.
    ///
    /// The users are 2–4 because a product's seller is derived as
    /// `product.id % 30 + 1`, so products 1–3 sell through users 2–4. Image URLs
    /// are empty so `ProductImage` draws its placeholder without a network request.
    nonisolated enum StubFixtures {
        static let products = """
        {
          "products": [
            {
              "id": 1,
              "title": "Stub Widget",
              "description": "A widget served by the stub network.",
              "category": "stubs",
              "price": 9.99,
              "discountPercentage": 10.48,
              "rating": 4.5,
              "stock": 99,
              "tags": ["stubs", "widgets"],
              "brand": "Stubco",
              "sku": "STB-WID-001",
              "weight": 4,
              "dimensions": { "width": 15.14, "height": 13.08, "depth": 22.99 },
              "warrantyInformation": "1 week warranty",
              "shippingInformation": "Ships in 3-5 business days",
              "availabilityStatus": "In Stock",
              "reviews": [
                {
                  "rating": 5,
                  "comment": "Highly impressed!",
                  "date": "2025-04-30T09:41:02.053Z",
                  "reviewerName": "Ray Viewer",
                  "reviewerEmail": "ray.viewer@stub.invalid"
                }
              ],
              "returnPolicy": "No return policy",
              "minimumOrderQuantity": 1,
              "meta": {
                "createdAt": "2025-10-09T14:47:01.588Z",
                "updatedAt": "2026-05-23T11:27:41.868Z",
                "barcode": "5784719087687",
                "qrCode": ""
              },
              "thumbnail": "",
              "images": []
            },
            {
              "id": 2,
              "title": "Stub Gadget",
              "description": "A gadget served by the stub network.",
              "category": "stubs",
              "price": 24.50,
              "discountPercentage": 0,
              "rating": 3.8,
              "stock": 12,
              "tags": ["stubs", "gadgets"],
              "sku": "STB-GAD-002",
              "weight": 2,
              "dimensions": { "width": 8.5, "height": 3.2, "depth": 12.0 },
              "warrantyInformation": "No warranty",
              "shippingInformation": "Ships overnight",
              "availabilityStatus": "Low Stock",
              "reviews": [],
              "returnPolicy": "30 days return policy",
              "minimumOrderQuantity": 2,
              "meta": {
                "createdAt": "2025-10-09T14:47:01.588Z",
                "updatedAt": "2026-05-23T11:27:41.868Z",
                "barcode": "5784719087694",
                "qrCode": ""
              },
              "thumbnail": "",
              "images": []
            },
            {
              "id": 3,
              "title": "Stub Gizmo",
              "description": "A gizmo served by the stub network.",
              "category": "stubs",
              "price": 120,
              "discountPercentage": 5.5,
              "rating": 4.1,
              "stock": 0,
              "tags": [],
              "brand": "Stubco",
              "sku": "STB-GIZ-003",
              "weight": 9,
              "dimensions": { "width": 30.0, "height": 20.0, "depth": 10.0 },
              "warrantyInformation": "2 year warranty",
              "shippingInformation": "Ships in 1 week",
              "availabilityStatus": "Out of Stock",
              "reviews": [],
              "returnPolicy": "No return policy",
              "minimumOrderQuantity": 1,
              "meta": {
                "createdAt": "2025-10-09T14:47:01.588Z",
                "updatedAt": "2026-05-23T11:27:41.868Z",
                "barcode": "5784719087700",
                "qrCode": ""
              },
              "thumbnail": "",
              "images": []
            }
          ]
        }
        """

        static let users = """
        {
          "users": [
            { "id": 2, "firstName": "Stella", "lastName": "Seller", "email": "stella.seller@stub.invalid", "image": "" },
            { "id": 3, "firstName": "Sam", "lastName": "Seller", "email": "sam.seller@stub.invalid", "image": "" },
            { "id": 4, "firstName": "Sasha", "lastName": "Seller", "email": "sasha.seller@stub.invalid", "image": "" }
          ]
        }
        """
    }
#endif
