//
//  TemplateApp.swift
//  App
//

import Products
import SwiftUI
import Users

@main
struct TemplateApp: App {
    @State private var container: AppContainer
    @State private var router: AppRouter

    // Each tab's root view model is built once and kept, rather than rebuilt
    // every time `body` runs. A view holds its view model with `let` and does
    // not own its lifetime, so whoever constructs it has to keep it alive —
    // otherwise every re-render would hand the view a new one and restart its
    // work.
    @State private var products: ProductViewModel
    @State private var users: UserViewModel

    init() {
        let container = AppContainer.live()
        let router = AppRouter()

        _container = State(wrappedValue: container)
        _router = State(wrappedValue: router)
        _products = State(wrappedValue: Products.viewModel(container, emit: router.handle))
        _users = State(wrappedValue: Users.viewModel(container, emit: router.handle))
    }

    var body: some Scene {
        WindowGroup {
            TabView(selection: $router.selectedTab) {
                Tab("Products", systemImage: "bag", value: AppRouter.Tab.products) {
                    NavigationStack(path: $router.productsStack) {
                        ProductView(viewModel: products)
                            .navigationTitle("Products")
                            .navigationDestinations(container: container, router: router)
                    }
                }
                Tab("Users", systemImage: "person.2", value: AppRouter.Tab.users) {
                    NavigationStack(path: $router.usersStack) {
                        UserView(viewModel: users)
                            .navigationTitle("Users")
                            .navigationDestinations(container: container, router: router)
                    }
                }
            }
            // The tab bar shrinks out of the way on a downward scroll and
            // returns on the way back up.
            .tabBarMinimizeBehavior(.onScrollDown)
        }
    }
}

private extension View {
    /// Registers every feature's routes on a navigation stack.
    ///
    /// Both stacks register all destinations because either can show either
    /// feature's screens — a product's seller opens a user profile.
    ///
    /// Unlike the tab roots, these view models are built here rather than held:
    /// SwiftUI calls this closure once per pushed route value and keeps the
    /// result for as long as that screen is on the stack.
    func navigationDestinations(container: AppContainer, router: AppRouter) -> some View {
        navigationDestination(for: AnyRoute.self) { route in
            switch route {
            case let .product(route):
                Products.view(route, container, emit: router.handle)
            case let .user(route):
                Users.view(route, container, emit: router.handle)
            }
        }
    }
}
