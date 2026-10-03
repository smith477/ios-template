// MainApp.swift

import Products
import SwiftUI
import Users

@main
struct MainApp: App {
    @State private var container: AppContainer
    @State private var router: AppRouter

    // Built once: the root views hold these as `let`, so rebuilding them per
    // render would restart their loads.
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
            .tabBarMinimizeBehavior(.onScrollDown)
            // Outside the `TabView` so a link naming a tab other than the one
            // on screen is still handled.
            .onOpenURL { router.open($0) }
        }
    }
}

private extension View {
    /// Registers every feature's routes. Either stack can show either feature,
    /// as a product's seller opens a user profile.
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
