// UserProfileView.swift

import SwiftUI

public struct UserProfileView: View {
    /// Creates the screen. The view model is held in `@State`, without which
    /// SwiftUI never redraws a pushed screen.
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
                ContentUnavailableView(String(localized: "Not found", bundle: .module), systemImage: "person.slash")
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
            LabeledContent(String(localized: "Name", bundle: .module), value: user.fullName)
            LabeledContent(String(localized: "Email", bundle: .module), value: user.email)
        }
        .navigationTitle(user.fullName)
        .navigationBarTitleDisplayMode(.inline)
    }
}
