import SwiftUI

struct UserManagementView: View {
    @Bindable var viewModel: AdminViewModel
    @State private var promoteUserID: String?

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                TextField("Search by username", text: $viewModel.searchQuery)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .padding(12)
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(.rect(cornerRadius: 12))

                Button {
                    Task { await viewModel.searchUsers() }
                } label: {
                    Image(systemName: "magnifyingglass")
                        .font(.headline)
                        .padding(12)
                        .background(Color.teal)
                        .foregroundStyle(.white)
                        .clipShape(.rect(cornerRadius: 12))
                }
            }
            .padding(16)

            if viewModel.searchResults.isEmpty {
                ContentUnavailableView("Search Users", systemImage: "person.magnifyingglass", description: Text("Search for users by username to manage accounts."))
            } else {
                List(viewModel.searchResults) { user in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(user.username)
                                .font(.headline)
                            CategoryBadge(text: user.role.displayName)
                        }

                        Spacer()

                        if user.role != .admin {
                            Button {
                                promoteUserID = user.id
                            } label: {
                                Text("Make Admin")
                                    .font(.caption.weight(.semibold))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                            }
                            .buttonStyle(.bordered)
                            .tint(.orange)
                            .clipShape(.capsule)
                        } else {
                            Image(systemName: "shield.checkered")
                                .foregroundStyle(.orange)
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .alert("Promote to Admin?", isPresented: Binding(
            get: { promoteUserID != nil },
            set: { if !$0 { promoteUserID = nil } }
        )) {
            Button("Promote", role: .destructive) {
                if let id = promoteUserID {
                    Task { await viewModel.promoteToAdmin(userID: id) }
                }
                promoteUserID = nil
            }
            Button("Cancel", role: .cancel) { promoteUserID = nil }
        } message: {
            Text("This user will gain full admin access. This action should only be performed for trusted team members.")
        }
    }
}
