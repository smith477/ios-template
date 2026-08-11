//
//  RoutingTests.swift
//  AppTests
//

import Foundation
import Products
import Testing
import Users

@testable import App

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
