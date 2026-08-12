// UserProfileView.swift

import Identity
import SwiftUI

public struct UserProfileView: View {
    /// `@State` for the same reason as `ProductDetailView`: a pushed screen
    /// holding its `@Observable` view model in a plain `let` is never
    /// invalidated when the view model changes.
    @State private var viewModel: UserProfileViewModel

    public init(viewModel: UserProfileViewModel) {
        _viewModel = State(wrappedValue: viewModel)
    }

    public var body: some View {
        Group {
            switch viewModel.state {
            case .loading:
                ProgressView()
            case let .loaded(user):
                profile(user)
            case .notFound:
                ContentUnavailableView("Not found", systemImage: "person.slash")
            case let .error(error):
                Text(error.localizedDescription)
            }
        }
        .task {
            await viewModel.load()
        }
    }

    private func profile(_ user: User) -> some View {
        List {
            LabeledContent("Name", value: user.fullName)
            LabeledContent("Email", value: user.email)
        }
        .navigationTitle(user.fullName)
        .navigationBarTitleDisplayMode(.inline)
    }
}
