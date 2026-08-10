//
//  RoutingTests.swift
//  AppTests
//

import Foundation
import Products
import Testing
import Users

@testable import App

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

/// Covers how the app turns events into stack changes.
@MainActor
struct AppRouterTests {
    @Test
    func aProductTapPushesOntoTheProductsStack() {
        let router = AppRouter()

        router.handle(.productTapped(id: 7))

        #expect(router.productsStack == [.product(.detail(id: 7))])
        #expect(router.usersStack.isEmpty)
        #expect(router.selectedTab == .products)
    }

    /// A Products event resolves to a screen in the Users tab.
    @Test
    func aSellerTapCrossesToTheUsersTab() {
        let router = AppRouter()

        router.handle(.sellerTapped(userId: 3))

        #expect(router.selectedTab == .users)
        #expect(router.usersStack == [.user(.profile(id: 3))])
        #expect(router.productsStack.isEmpty)
    }

    /// Each tab keeps its own stack.
    @Test
    func tabsKeepSeparateStacks() {
        let router = AppRouter()

        router.handle(.productTapped(id: 1))
        router.handle(.userTapped(id: 2))

        #expect(router.productsStack == [.product(.detail(id: 1))])
        #expect(router.usersStack == [.user(.profile(id: 2))])
    }

    /// Crossing into an unselected tab replaces whatever it was showing.
    @Test
    func crossingIntoABusyTabReplacesItsStack() {
        let router = AppRouter()
        router.handle(.userTapped(id: 8))
        router.handle(.userTapped(id: 9))

        router.handle(.sellerTapped(userId: 3))

        #expect(router.usersStack == [.user(.profile(id: 3))])
        #expect(router.selectedTab == .users)
    }

    /// Routing to the selected tab pushes rather than replacing, preserving
    /// the visible back stack. Not reachable through events today.
    @Test
    func crossingIntoTheCurrentTabPushesInsteadOfReplacing() {
        let router = AppRouter()
        router.selectedTab = .users
        router.handle(.userTapped(id: 8))

        router.crossTo(.user(.profile(id: 3)), in: .users)

        #expect(router.usersStack == [.user(.profile(id: 8)), .user(.profile(id: 3))])
    }

    /// Repeated taps before a push renders do not stack the same screen.
    @Test
    func repeatedTapsDoNotStackTheSameScreen() {
        let router = AppRouter()

        router.handle(.productTapped(id: 4))
        router.handle(.productTapped(id: 4))

        #expect(router.productsStack == [.product(.detail(id: 4))])
    }

    /// Only consecutive duplicates are suppressed.
    @Test
    func theSameScreenCanRecurLaterInAStack() {
        let router = AppRouter()

        router.handle(.productTapped(id: 4))
        router.handle(.productTapped(id: 5))
        router.handle(.productTapped(id: 4))

        #expect(router.productsStack == [
            .product(.detail(id: 4)),
            .product(.detail(id: 5)),
            .product(.detail(id: 4)),
        ])
    }

    /// Stacks survive encoding, as state restoration will require.
    @Test
    func routesRoundTripThroughCoding() throws {
        let stack: [AnyRoute] = [.product(.detail(id: 4)), .user(.profile(id: 9))]

        let data = try JSONEncoder().encode(stack)
        let decoded = try JSONDecoder().decode([AnyRoute].self, from: data)

        #expect(decoded == stack)
    }

    /// Routes differing only by id are distinct stack entries.
    @Test
    func differentProductsAreDistinctEntries() {
        let router = AppRouter()

        router.handle(.productTapped(id: 1))
        router.handle(.productTapped(id: 2))

        #expect(router.productsStack == [.product(.detail(id: 1)), .product(.detail(id: 2))])
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
