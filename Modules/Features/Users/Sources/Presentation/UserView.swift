// UserView.swift

import Identity
import SwiftUI

public struct UserView: View {
    @State private var viewModel: UserViewModel

    public init(viewModel: UserViewModel) {
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
            await viewModel.getUsers()
        }
    }

    private var listView: some View {
        List(viewModel.users) { user in
            VStack(alignment: .leading) {
                Text(user.fullName)
                Text(user.email)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
