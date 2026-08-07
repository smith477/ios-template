// ProductView.swift

import SwiftUI

struct ProductView: View {
    @State var viewModel: ProductViewModel

    var body: some View {
        Group {
            switch viewModel.loadingState {
            case .loading:
                ProgressView()
            case .loaded:
                listView
            case let .error(error):
                Text(error.localizedDescription)
            }
        }
        .task {
            await viewModel.getProducts()
        }
    }

    var listView: some View {
        List(viewModel.products) { product in
            Text(product.title)
        }
    }
}
