//
//  TemplateApp.swift
//  App
//

import Products
import SwiftUI
import Users

@main
struct TemplateApp: App {
    @State private var container = AppContainer()

    var body: some Scene {
        WindowGroup {
            TabView {
                Tab("Products", systemImage: "bag") {
                    ProductView(viewModel: Products.viewModel(container))
                }
                Tab("Users", systemImage: "person.2") {
                    UserView(viewModel: Users.viewModel(container))
                }
            }
        }
    }
}
