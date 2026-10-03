// RoutingTests.swift

import Foundation
import Products
import Testing
import Users

@testable import App

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

    /// Back then returns to the product rather than leaving the Products tab.
    @Test
    func aSellerTapPushesTheProfileOntoTheProductsStack() {
        let router = AppRouter()
        router.handle(.productTapped(id: 7))

        router.handle(.sellerTapped(userId: 3))

        #expect(router.productsStack == [.product(.detail(id: 7)), .user(.profile(id: 3))])
        #expect(router.selectedTab == .products)
    }

    @Test
    func aSellerTapDoesNotDisturbTheUsersTab() {
        let router = AppRouter()
        router.handle(.userTapped(id: 8))
        router.handle(.userTapped(id: 9))

        router.handle(.sellerTapped(userId: 3))

        #expect(router.usersStack == [.user(.profile(id: 8)), .user(.profile(id: 9))])
        #expect(router.selectedTab == .products)
    }

    @Test
    func tabsKeepSeparateStacks() {
        let router = AppRouter()

        router.handle(.productTapped(id: 1))
        router.handle(.userTapped(id: 2))

        #expect(router.productsStack == [.product(.detail(id: 1))])
        #expect(router.usersStack == [.user(.profile(id: 2))])
    }

    @Test
    func crossingIntoABusyTabReplacesItsStack() {
        let router = AppRouter()
        router.handle(.userTapped(id: 8))
        router.handle(.userTapped(id: 9))

        router.crossTo(.user(.profile(id: 3)), in: .users)

        #expect(router.usersStack == [.user(.profile(id: 3))])
        #expect(router.selectedTab == .users)
    }

    @Test
    func crossingIntoTheCurrentTabPushesInsteadOfReplacing() {
        let router = AppRouter()
        router.selectedTab = .users
        router.handle(.userTapped(id: 8))

        router.crossTo(.user(.profile(id: 3)), in: .users)

        #expect(router.usersStack == [.user(.profile(id: 8)), .user(.profile(id: 3))])
    }

    @Test
    func repeatedTapsDoNotStackTheSameScreen() {
        let router = AppRouter()

        router.handle(.productTapped(id: 4))
        router.handle(.productTapped(id: 4))

        #expect(router.productsStack == [.product(.detail(id: 4))])
    }

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

    /// State restoration needs stacks to encode.
    @Test
    func routesRoundTripThroughCoding() throws {
        let stack: [AnyRoute] = [.product(.detail(id: 4)), .user(.profile(id: 9))]

        let data = try JSONEncoder().encode(stack)
        let decoded = try JSONDecoder().decode([AnyRoute].self, from: data)

        #expect(decoded == stack)
    }

    @Test
    func differentProductsAreDistinctEntries() {
        let router = AppRouter()

        router.handle(.productTapped(id: 1))
        router.handle(.productTapped(id: 2))

        #expect(router.productsStack == [.product(.detail(id: 1)), .product(.detail(id: 2))])
    }
}
