//
//  ContentView.swift
//  ios-template
//
//  Created by Dusan Kovacevic on 05/12/2025.
//

import APIClient
import CoreData
import SwiftUI

struct ContentView: View {
    var body: some View {
        ProductView(viewModel: AppContainer.shared.makeProductViewModel())
    }
}
