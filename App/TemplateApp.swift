//
//  TemplateApp.swift
//  App
//

import Products
import SwiftUI
import Users

@main
struct TemplateApp: App {
    @State private var container = AppContainer.live()
    @State private var router = AppRouter()

    var body: some Scene {
        WindowGroup {
            TabView(selection: $router.selectedTab) {
                Tab("Products", systemImage: "bag", value: AppRouter.Tab.products) {
                    NavigationStack(path: $router.productsStack) {
                        ProductView(
                            viewModel: Products.viewModel(container, emit: router.handle)
                        )
                        .navigationTitle("Products")
                        .navigationDestinations(container: container, router: router)
                    }
                }
                Tab("Users", systemImage: "person.2", value: AppRouter.Tab.users) {
                    NavigationStack(path: $router.usersStack) {
                        UserView(
                            viewModel: Users.viewModel(container, emit: router.handle)
                        )
                        .navigationTitle("Users")
                        .navigationDestinations(container: container, router: router)
                    }
                }
            }
        }
    }
}

private extension View {
    /// Registers every feature's routes on a navigation stack.
    ///
    /// Both stacks register all destinations because either can show either
    /// feature's screens — a product's seller opens a user profile.
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
