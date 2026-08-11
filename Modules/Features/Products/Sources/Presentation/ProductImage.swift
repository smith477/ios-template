// ProductImage.swift

import SwiftUI

/// A product image loaded from its URL, with a placeholder while it loads and
/// wherever there is no usable URL — the domain model maps a missing image
/// to `""`.
///
/// - Note: `AsyncImage` caches no further than `URLSession`'s small default,
///   so a long list refetches while scrolling. Left for whoever adopts this
///   template to replace with their own image cache.
struct ProductImage: View {
    let url: String
    var contentMode: ContentMode = .fill

    var body: some View {
        if let url = URL(string: url), !url.absoluteString.isEmpty {
            AsyncImage(url: url) { phase in
                switch phase {
                case let .success(image):
                    image.resizable().aspectRatio(contentMode: contentMode)
                case .empty:
                    placeholder(icon: nil).overlay(ProgressView())
                case .failure:
                    placeholder(icon: "exclamationmark.triangle")
                @unknown default:
                    placeholder(icon: "photo")
                }
            }
        } else {
            placeholder(icon: "photo")
        }
    }

    private func placeholder(icon: String?) -> some View {
        Rectangle()
            .fill(.fill.tertiary)
            .overlay {
                if let icon {
                    Image(systemName: icon)
                        .foregroundStyle(.secondary)
                }
            }
    }
}
