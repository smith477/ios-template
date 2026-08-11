// ProductView.swift

import SwiftUI

public struct ProductView: View {
    private let viewModel: ProductViewModel

    public init(viewModel: ProductViewModel) {
        self.viewModel = viewModel
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
                HStack(spacing: 12) {
                    ProductImage(url: product.thumbnail)
                        .frame(width: 44, height: 44)
                        .clipShape(.rect(cornerRadius: 8))

                    Text(product.title)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                // Must be inside the label: `.plain` hit-tests the label's own
                // shape, so outside the Button the row's gaps ignore taps.
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("product-row-\(product.id)")
        }
        .refreshable {
            await viewModel.refresh()
        }
    }
}
