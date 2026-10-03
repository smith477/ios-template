// DeepLinkTests.swift

import Foundation
import Products
import Testing
import Users

@testable import App

@MainActor
struct DeepLinkTests {
    // MARK: - Parsing

    @Test
    func aProductLinkNamesThatProduct() throws {
        let link = try #require(DeepLink(link("products/7")))

        #expect(link.tab == .products)
        #expect(link.route == .product(.detail(id: 7)))
    }

    @Test
    func aUserLinkNamesThatUser() throws {
        let link = try #require(DeepLink(link("users/3")))

        #expect(link.tab == .users)
        #expect(link.route == .user(.profile(id: 3)))
    }

    @Test
    func aBareTabLinkNamesNoRoute() throws {
        let link = try #require(DeepLink(link("users")))

        #expect(link.tab == .users)
        #expect(link.route == nil)
    }

    @Test
    func aTrailingSlashIsIgnored() throws {
        let link = try #require(DeepLink(link("products/")))

        #expect(link.tab == .products)
        #expect(link.route == nil)
    }

    /// `DeepLinkScheme` and `CFBundleURLTypes` are separate Info.plist entries;
    /// this keeps them equal.
    @Test
    func theSchemeIsOneTheAppRegisters() throws {
        let types = try #require(Bundle.main.object(forInfoDictionaryKey: "CFBundleURLTypes") as? [[String: Any]])
        let schemes = types.flatMap { $0["CFBundleURLSchemes"] as? [String] ?? [] }

        #expect(schemes.contains(DeepLink.scheme))
    }

    @Test
    func aForeignSchemeIsRejected() {
        #expect(DeepLink(URL(string: "https://example.com/products/7")!) == nil)
        #expect(DeepLink(URL(string: "other://products/7")!) == nil)
    }

    @Test
    func anUnknownHostIsRejected() {
        #expect(DeepLink(link("orders/7")) == nil)
    }

    /// Ids are server-assigned positives, so anything else is a malformed link.
    @Test(arguments: [
        "products/7x",
        "products/abc",
        "products/7.5",
        "products/-2",
        "products/0",
    ])
    func anUnusableIdIsRejected(_ path: String) {
        #expect(DeepLink(link(path)) == nil)
    }

    @Test
    func aRejectedIdDoesNotDegradeToTheTabRoot() {
        #expect(DeepLink(link("users/abc")) == nil)
    }

    @Test
    func anOverlongPathIsRejected() {
        #expect(DeepLink(link("products/7/reviews")) == nil)
    }

    // MARK: - Acting on a link

    @Test
    func openingAProductLinkCrossesToThatProduct() {
        let router = AppRouter()
        router.selectedTab = .users

        #expect(router.open(link("products/7")))

        #expect(router.selectedTab == .products)
        #expect(router.productsStack == [.product(.detail(id: 7))])
    }

    @Test
    func openingALinkReplacesTheTargetStack() {
        let router = AppRouter()
        router.selectedTab = .products
        router.handle(.userTapped(id: 8))
        router.handle(.userTapped(id: 9))

        router.open(link("users/3"))

        #expect(router.usersStack == [.user(.profile(id: 3))])
        #expect(router.selectedTab == .users)
    }

    /// Pushing keeps Back returning to what the user was looking at.
    @Test
    func openingALinkIntoTheSelectedTabPushes() {
        let router = AppRouter()
        router.selectedTab = .users
        router.handle(.userTapped(id: 8))

        router.open(link("users/3"))

        #expect(router.usersStack == [.user(.profile(id: 8)), .user(.profile(id: 3))])
        #expect(router.selectedTab == .users)
    }

    @Test
    func openingATabLinkClearsThatStack() {
        let router = AppRouter()
        router.handle(.productTapped(id: 1))
        router.handle(.productTapped(id: 2))

        router.open(link("products"))

        #expect(router.selectedTab == .products)
        #expect(router.productsStack.isEmpty)
    }

    @Test
    func aTabLinkIsIdempotent() {
        let router = AppRouter()

        router.open(link("users"))
        router.handle(.userTapped(id: 4))
        router.open(link("users"))

        #expect(router.usersStack.isEmpty)
        #expect(router.selectedTab == .users)
    }

    @Test
    func openingAnUnknownLinkChangesNothing() {
        let router = AppRouter()
        router.handle(.productTapped(id: 1))

        #expect(router.open(link("orders/7")) == false)

        #expect(router.productsStack == [.product(.detail(id: 1))])
        #expect(router.usersStack.isEmpty)
        #expect(router.selectedTab == .products)
    }
}

/// Builds a link in this app's own scheme, so the tests survive a rename.
@MainActor
private func link(_ path: String) -> URL {
    URL(string: "\(DeepLink.scheme)://\(path)")!
}
