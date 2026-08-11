//
//  ProductEventTests.swift
//  ProductsTests
//

import Foundation
import Testing

@testable import Products

/// Covers what a feature emits. Feature view models hold no router, so their
/// navigation intent is assertable without a stack, a view, or a test double.
@MainActor
struct FeatureEventTests {
    @Test
    func tappingAProductEmitsIt() {
        var events: [ProductEvent] = []
        let viewModel = ProductViewModel(repository: StubProductRepository(), emit: { events.append($0) })

        viewModel.didTapProduct(id: 42)

        #expect(events == [.productTapped(id: 42)])
    }

    /// Asserts the event, not the id: the seller is a placeholder for an API
    /// field that does not exist yet.
    @Test
    func tappingTheSellerEmitsSellerTapped() async {
        var events: [ProductEvent] = []
        let viewModel = await loadedDetail(productId: 7, emit: { events.append($0) })

        viewModel.didTapSeller()

        #expect(events.count == 1)
        if case let .sellerTapped(userId) = events.first {
            #expect(userId > 0)
        } else {
            Issue.record("expected a sellerTapped event, got \(events)")
        }
    }

    /// The placeholder seller varies between products and is stable for any
    /// one product.
    @Test
    func sellersVaryByProductAndAreStable() async {
        var first: [ProductEvent] = []
        var second: [ProductEvent] = []
        var firstAgain: [ProductEvent] = []

        await loadedDetail(productId: 7, emit: { first.append($0) }).didTapSeller()
        await loadedDetail(productId: 8, emit: { second.append($0) }).didTapSeller()
        await loadedDetail(productId: 7, emit: { firstAgain.append($0) }).didTapSeller()

        #expect(first != second)
        #expect(first == firstAgain)
    }

    private func loadedDetail(
        productId: Int,
        emit: @escaping (ProductEvent) -> Void
    ) async -> ProductDetailViewModel {
        let viewModel = ProductDetailViewModel(
            repository: StubProductRepository(products: [.stub(id: productId)]),
            id: productId,
            emit: emit
        )
        await viewModel.load()
        return viewModel
    }

    /// Tapping the seller before the product loads emits nothing.
    @Test
    func tappingTheSellerBeforeLoadingEmitsNothing() {
        var events: [ProductEvent] = []
        let viewModel = ProductDetailViewModel(
            repository: StubProductRepository(),
            id: 1,
            emit: { events.append($0) }
        )

        viewModel.didTapSeller()

        #expect(events.isEmpty)
    }

    /// Omitting `emit` discards events without failing. The two view models
    /// differ only in whether `emit` was passed.
    @Test
    func omittingEmitDropsEventsSilently() {
        var wired: [ProductEvent] = []
        let withEmit = ProductViewModel(repository: StubProductRepository(), emit: { wired.append($0) })
        let withoutEmit = ProductViewModel(repository: StubProductRepository())

        withEmit.didTapProduct(id: 1)
        withoutEmit.didTapProduct(id: 1)

        #expect(wired == [.productTapped(id: 1)])
    }
}

private struct StubProductRepository: ProductRepository {
    var products: [Product] = []

    func getProducts(policy: CachePolicy) async throws -> [Product] { products }
}

private extension Product {
    static func stub(id: Int) -> Product {
        Product(
            id: id,
            title: "Widget",
            description: "",
            category: "",
            price: 1,
            tags: [],
            brand: nil,
            meta: Meta(createdAt: .distantPast, updatedAt: .distantPast),
            thumbnail: "",
            images: []
        )
    }
}
