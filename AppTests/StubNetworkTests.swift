// StubNetworkTests.swift

import APIClient
import Foundation
import Testing

@testable import App
@testable import Products
@testable import Users

/// The stub network the UI tests run against. The fixtures stand in for the
/// live API's contract, so they are decoded through the real response types
/// and fetched through the real clients rather than checked by eye.
struct StubNetworkTests {
    @Test
    func theProductsFixtureDecodesThroughTheResponseType() throws {
        let response = try JSONDecoder().decode(ProductsResponse.self, from: Data(StubFixtures.products.utf8))

        #expect(response.products.map(\.id) == [1, 2, 3])
        #expect(response.products.first?.title == "Stub Widget")
    }

    @Test
    func theUsersFixtureDecodesThroughTheResponseType() throws {
        let response = try JSONDecoder().decode(UsersResponse.self, from: Data(StubFixtures.users.utf8))

        #expect(response.users.map(\.id) == [2, 3, 4])
    }

    @Test
    func theProductsClientFetchesTheFixtureThroughTheStub() async throws {
        let products = try await ProductAPISessionClient(apiClient: stubbedClient()).fetchProducts()

        #expect(products.map(\.title) == ["Stub Widget", "Stub Gadget", "Stub Gizmo"])
    }

    @Test
    func theUsersEndpointFetchesTheFixtureThroughTheStub() async throws {
        let response: UsersResponse = try await stubbedClient().send(UserEndpoint.list)

        #expect(response.users.map(\.firstName) == ["Stella", "Sam", "Sasha"])
    }

    /// A path the stub does not serve answers 404 rather than reaching the
    /// network, so a new endpoint fails visibly in a stubbed run.
    @Test
    func anUnknownPathAnswersNotFound() async {
        await #expect(throws: APIError.notFound) {
            let _: UsersResponse = try await stubbedClient().send(UnknownEndpoint())
        }
    }

    /// Every product's seller resolves to a fixture user, so tapping the
    /// seller in a stubbed run opens a profile rather than "not found". Read
    /// from the emitted event because the seller rule is private to Products.
    @Test(arguments: [1, 2, 3]) @MainActor
    func everyProductsSellerIsAFixtureUser(productId: Int) async throws {
        var events: [ProductEvent] = []
        let viewModel = ProductDetailViewModel(
            repository: FetchingProductRepository(client: ProductAPISessionClient(apiClient: stubbedClient())),
            id: productId,
            emit: { events.append($0) }
        )
        await viewModel.load()
        viewModel.didTapSeller()

        guard case let .sellerTapped(userId) = try #require(events.first) else {
            Issue.record("expected a sellerTapped event, got \(events)")
            return
        }
        let response: UsersResponse = try await stubbedClient().send(UserEndpoint.list)
        #expect(response.users.map(\.id).contains(userId))
    }

    private func stubbedClient() -> APIClient {
        APIClient(baseURL: URL(string: "https://stub.invalid")!, session: StubURLProtocol.session())
    }
}

private struct UnknownEndpoint: Endpoint {
    let path = "/carts"
    let method = HTTPMethod.GET
}

/// Always fetches, so the detail view model sees exactly what the stub served.
private struct FetchingProductRepository: ProductRepository {
    let client: ProductApiClient

    func getProducts(policy _: CachePolicy) async throws -> [Product] {
        try await client.fetchProducts()
    }
}
