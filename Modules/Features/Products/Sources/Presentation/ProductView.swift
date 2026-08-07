// ProductView.swift

import SwiftUI

public struct ProductView: View {
    @State private var viewModel: ProductViewModel

    public init(viewModel: ProductViewModel) {
        _viewModel = State(wrappedValue: viewModel)
    }

    public var body: some View {
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

    private var listView: some View {
        List(viewModel.products) { product in
            Text(product.title)
        }
        .refreshable {
            await viewModel.refresh()
        }
    }
}
