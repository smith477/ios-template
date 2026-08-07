//
//  ContentView.swift
//  App
//

import APIClient
import CoreData
import SwiftUI

struct ContentView: View {
    var body: some View {
        ProductView(viewModel: AppContainer.shared.makeProductViewModel())
    }
}
