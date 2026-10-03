// ProductEventTests.swift

import Foundation
import Testing

@testable import Products

/// View models hold no router, so their events are assertable without a stack
/// or a view.
@MainActor
struct FeatureEventTests {
    @Test
    func tappingAProductEmitsIt() {
        var events: [ProductEvent] = []
        let viewModel = ProductViewModel(repository: StubProductRepository(), emit: { events.append($0) })

        viewModel.didTapProduct(id: 42)

        #expect(events == [.productTapped(id: 42)])
    }

    /// Asserts the event, not the id: the seller is a placeholder.
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

    func getProduct(id: Int, policy: CachePolicy) async throws -> Product? {
        products.first { $0.id == id }
    }
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
