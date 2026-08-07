//
//  TemplateApp.swift
//  App
//

import Products
import SwiftUI

@main
struct TemplateApp: App {
    @State private var container = AppContainer()

    var body: some Scene {
        WindowGroup {
            ProductView(viewModel: Products.viewModel(container))
        }
    }
}
