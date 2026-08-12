// UserView.swift

import Identity
import SwiftUI

public struct UserView: View {
    private let viewModel: UserViewModel

    public init(viewModel: UserViewModel) {
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
            await viewModel.getUsers()
        }
    }

    private var listView: some View {
        List(viewModel.users) { user in
            Button {
                viewModel.didTapUser(id: user.id)
            } label: {
                HStack {
                    VStack(alignment: .leading) {
                        Text(user.fullName)
                        Text(user.email)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
        }
    }
}
