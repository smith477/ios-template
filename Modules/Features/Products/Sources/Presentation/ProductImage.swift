// ProductImage.swift

import SwiftUI

/// A product image loaded from its URL, with a placeholder while loading or when
/// the URL is empty.
///
/// - Note: `AsyncImage` caches only in `URLSession`'s small default cache; an app
///   with long lists wants its own image cache.
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
