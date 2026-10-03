// StubNetworkTests.swift

import APIClient
import CoreData
import Foundation
import Persistence
import Testing

@testable import App
@testable import Products
@testable import Users

/// Decodes the fixtures through the real response types and fetches them
/// through the real clients.
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

    @Test(arguments: [1, 2, 3, 50])
    func eachProductFixtureDecodesById(id: Int) throws {
        let body = try #require(StubFixtures.product[id])
        let response = try JSONDecoder().decode(ProductResponse.self, from: Data(body.utf8))

        #expect(response.id == id)
    }

    /// A product outside the list, fetched by id through the real data layer.
    @Test @MainActor
    func productFiftyLoadsThroughTheStub() async throws {
        let viewModel = try stubbedDetail(id: 50)

        await viewModel.load()

        guard case let .loaded(product) = viewModel.state else {
            Issue.record("product 50 did not load: \(viewModel.state)")
            return
        }
        #expect(product.id == 50)
        #expect(product.title == "Stub Fifty")
    }

    @Test @MainActor
    func anUnknownProductIsNotFound() async throws {
        let viewModel = try stubbedDetail(id: 999)

        await viewModel.load()

        guard case .notFound = viewModel.state else {
            Issue.record("expected notFound, got \(viewModel.state)")
            return
        }
    }

    @Test
    func theUsersEndpointFetchesTheFixtureThroughTheStub() async throws {
        let response: UsersResponse = try await stubbedClient().send(UserEndpoint.list)

        #expect(response.users.map(\.firstName) == ["Stella", "Sam", "Sasha"])
    }

    /// A new endpoint then fails visibly in a stubbed run rather than reaching the
    /// network.
    @Test
    func anUnknownPathAnswersNotFound() async {
        await #expect(throws: APIError.notFound) {
            let _: UsersResponse = try await stubbedClient().send(UnknownEndpoint())
        }
    }

    /// Read from the emitted event, because the seller rule is private to Products.
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

    @Test @MainActor
    func theStubbedContainerLoadsTheFixturesIntoAnInMemoryStore() async throws {
        let container = AppContainer.stubbed()

        let store = try #require(
            container.storageProvider.viewContext.persistentStoreCoordinator?.persistentStores.first
        )
        #expect(store.type == NSInMemoryStoreType)

        let viewModel = Products.viewModel(container, emit: { _ in })
        await viewModel.getProducts()

        #expect(Set(viewModel.products.map(\.title)) == ["Stub Widget", "Stub Gadget", "Stub Gizmo"])
    }

    /// A detail view model over the stub, an empty in-memory store and its own
    /// list record.
    @MainActor
    private func stubbedDetail(id: Int) throws -> ProductDetailViewModel {
        let repository = ProductDataRepository(
            apiClient: ProductAPISessionClient(apiClient: stubbedClient()),
            storage: ProductCoreDataStorage(
                storageProvider: try .inMemory(modelName: "ios_template"),
                listRecord: ProductListRecord(suiteName: UUID().uuidString)
            )
        )
        return ProductDetailViewModel(repository: repository, id: id)
    }

    private func stubbedClient() -> APIClient {
        APIClient(baseURL: URL(string: "https://stub.invalid")!, session: StubURLProtocol.session())
    }
}

private struct UnknownEndpoint: Endpoint {
    let path = "/carts"
    let method = HTTPMethod.GET
}

/// A repository that always fetches, so the view model sees what the stub served.
private struct FetchingProductRepository: ProductRepository {
    let client: ProductApiClient

    func getProducts(policy _: CachePolicy) async throws -> [Product] {
        try await client.fetchProducts()
    }

    func getProduct(id: Int, policy _: CachePolicy) async throws -> Product? {
        try await client.fetchProduct(id: id)
    }
}
