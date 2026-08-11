// ProductImage.swift

import SwiftUI

/// A product image loaded from its URL, with a placeholder while it loads and
/// wherever there is no usable URL.
///
/// An empty string is a normal value here rather than an error: the domain
/// model maps a missing image to `""`, so a product with no picture arrives
/// looking the same as one whose download failed.
///
/// - Note: `AsyncImage` does no caching of its own beyond `URLSession`'s small
///   default, so scrolling a long list refetches. That is left as it is: a
///   template should not ship an image cache its users have to understand
///   before replacing it with whichever one they already use.
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
