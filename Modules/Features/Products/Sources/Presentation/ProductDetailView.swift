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
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                hero(product)

                VStack(alignment: .leading, spacing: 8) {
                    Text(product.title).font(.title2.weight(.semibold))
                    Text(product.price, format: .currency(code: "USD"))
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    Text(product.description)
                }
                .padding(.horizontal)

                sellerRow
                    .padding(.horizontal)
            }
            .padding(.bottom, 32)
        }
        .navigationTitle(product.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    /// `backgroundExtensionEffect` mirrors and blurs the image outwards rather
    /// than leaving a hard edge under the navigation bar's glass.
    private func hero(_ product: Product) -> some View {
        ProductImage(url: product.thumbnail)
            .frame(height: 280)
            .frame(maxWidth: .infinity)
            .clipped()
            .backgroundExtensionEffect()
    }

    private var sellerRow: some View {
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
            .padding()
            // Inside the label, for the same reason as the rows in `ProductView`.
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 16))
        .accessibilityIdentifier("seller-row")
    }
}
