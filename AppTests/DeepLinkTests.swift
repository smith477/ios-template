// DeepLinkTests.swift

import Foundation
import Products
import Testing
import Users

@testable import App

/// Covers the deep-link grammar, and what a link does to the stacks.
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

    /// A link may name a tab without naming a screen in it.
    @Test
    func aBareTabLinkNamesNoRoute() throws {
        let link = try #require(DeepLink(link("users")))

        #expect(link.tab == .users)
        #expect(link.route == nil)
    }

    /// A trailing slash leaves an empty path component behind; it should read
    /// the same as the link without one.
    @Test
    func aTrailingSlashIsIgnored() throws {
        let link = try #require(DeepLink(link("products/")))

        #expect(link.tab == .products)
        #expect(link.route == nil)
    }

    /// The scheme `DeepLink` accepts is one iOS actually routes to this app.
    /// Both come from `urlScheme` in `Project.swift`, but as two Info.plist
    /// entries; this is what notices if they are ever set apart.
    @Test
    func theSchemeIsOneTheAppRegisters() throws {
        let types = try #require(Bundle.main.object(forInfoDictionaryKey: "CFBundleURLTypes") as? [[String: Any]])
        let schemes = types.flatMap { $0["CFBundleURLSchemes"] as? [String] ?? [] }

        #expect(schemes.contains(DeepLink.scheme))
    }

    /// Another app's scheme is not this app's link, even at a familiar path.
    @Test
    func aForeignSchemeIsRejected() {
        #expect(DeepLink(URL(string: "https://example.com/products/7")!) == nil)
        #expect(DeepLink(URL(string: "other://products/7")!) == nil)
    }

    @Test
    func anUnknownHostIsRejected() {
        #expect(DeepLink(link("orders/7")) == nil)
    }

    /// An id that is not a positive number is refused rather than
    /// approximated: ids are server-assigned positives, so anything else is a
    /// malformed link, and following it would only fetch nothing.
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

    /// A rejected id fails the parse rather than falling back to the tab root,
    /// which would be a destination the link did not name.
    @Test
    func aRejectedIdDoesNotDegradeToTheTabRoot() {
        #expect(DeepLink(link("users/abc")) == nil)
    }

    /// A deeper path means something this grammar does not define, so it is
    /// refused rather than read as its prefix.
    @Test
    func anOverlongPathIsRejected() {
        #expect(DeepLink(link("products/7/reviews")) == nil)
    }

    // MARK: - Acting on a link

    /// A link into an unselected tab selects it and lands on the named screen.
    @Test
    func openingAProductLinkCrossesToThatProduct() {
        let router = AppRouter()
        router.selectedTab = .users

        #expect(router.open(link("products/7")))

        #expect(router.selectedTab == .products)
        #expect(router.productsStack == [.product(.detail(id: 7))])
    }

    /// The user asked to be at that screen, so they arrive there rather than
    /// on top of what the tab was showing. This is what separates `crossTo`
    /// from `push`.
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

    /// A link into the tab already on screen pushes rather than replacing, so
    /// Back still returns to what the user was looking at.
    @Test
    func openingALinkIntoTheSelectedTabPushes() {
        let router = AppRouter()
        router.selectedTab = .users
        router.handle(.userTapped(id: 8))

        router.open(link("users/3"))

        #expect(router.usersStack == [.user(.profile(id: 8)), .user(.profile(id: 3))])
        #expect(router.selectedTab == .users)
    }

    /// A bare tab link lands on that tab's root.
    @Test
    func openingATabLinkClearsThatStack() {
        let router = AppRouter()
        router.handle(.productTapped(id: 1))
        router.handle(.productTapped(id: 2))

        router.open(link("products"))

        #expect(router.selectedTab == .products)
        #expect(router.productsStack.isEmpty)
    }

    /// Following the same tab link twice ends where following it once does.
    @Test
    func aTabLinkIsIdempotent() {
        let router = AppRouter()

        router.open(link("users"))
        router.handle(.userTapped(id: 4))
        router.open(link("users"))

        #expect(router.usersStack.isEmpty)
        #expect(router.selectedTab == .users)
    }

    /// An unparsable URL leaves the user where they were.
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

/// A link in this app's own scheme, so the tests follow a rename of the app
/// rather than pinning the template's scheme.
@MainActor
private func link(_ path: String) -> URL {
    URL(string: "\(DeepLink.scheme)://\(path)")!
}
