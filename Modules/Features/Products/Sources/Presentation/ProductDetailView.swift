// ProductDetailView.swift

import SwiftUI

public struct ProductDetailView: View {
    private let viewModel: ProductDetailViewModel

    public init(viewModel: ProductDetailViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        Group {
            switch viewModel.state {
            case .loading:
                ProgressView()
            case let .loaded(product):
                detail(product)
            case .notFound:
                ContentUnavailableView("Not found", systemImage: "questionmark")
            case let .error(error):
                Text(error.localizedDescription)
            }
        }
        .task {
            await viewModel.load()
        }
    }

    private func detail(_ product: Product) -> some View {
        List {
            Section {
                Text(product.title).font(.headline)
                Text(product.description)
                Text(product.price, format: .currency(code: "USD"))
            }

            Section {
                Button {
                    viewModel.didTapSeller()
                } label: {
                    HStack {
                        Label("Seller", systemImage: "person.crop.circle")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
                .buttonStyle(.plain)
                .contentShape(.rect)
                .accessibilityIdentifier("seller-row")
            }
        }
        .navigationTitle(product.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}
