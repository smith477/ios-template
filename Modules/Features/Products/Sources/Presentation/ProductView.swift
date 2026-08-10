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
            Button {
                viewModel.didTapProduct(id: product.id)
            } label: {
                HStack {
                    Text(product.title)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            .buttonStyle(.plain)
            // Whole row hittable, not just the text.
            .contentShape(.rect)
            // Identified by id rather than title: titles come from the API.
            .accessibilityIdentifier("product-row-\(product.id)")
        }
        .refreshable {
            await viewModel.refresh()
        }
    }
}
