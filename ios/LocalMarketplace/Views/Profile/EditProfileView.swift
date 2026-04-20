import SwiftUI
import PhotosUI

struct EditProfileView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    @Bindable var viewModel: ProfileViewModel

    @State private var selectedItem: PhotosPickerItem?

    var body: some View {
        List {
            Section {
                HStack {
                    Spacer()
                    VStack(spacing: 12) {
                        avatarView
                            .frame(width: 100, height: 100)

                        PhotosPicker(selection: $selectedItem, matching: .images) {
                            Text(hasAvatar ? "Change Photo" : "Add Photo")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.teal)
                        }
                    }
                    Spacer()
                }
                .listRowBackground(Color.clear)
            }

            Section("Display Name") {
                TextField("Your name", text: $viewModel.editDisplayName)
                    .textContentType(.name)
                    .autocorrectionDisabled()
            }

            Section("Bio") {
                TextField("Tell others about yourself...", text: $viewModel.editBio, axis: .vertical)
                    .lineLimit(3...6)
            }

            Section {
                HStack {
                    Text("Username")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(appState.currentUser?.username ?? "")
                        .foregroundStyle(.primary)
                }

                HStack {
                    Text("Role")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(appState.currentRole.displayName)
                        .foregroundStyle(.primary)
                }

                HStack {
                    Text("Joined")
                        .foregroundStyle(.secondary)
                    Spacer()
                    if let date = appState.currentUser?.createdAt {
                        Text(date, format: .dateTime.month(.wide).year())
                            .foregroundStyle(.primary)
                    } else {
                        Text("—")
                            .foregroundStyle(.tertiary)
                    }
                }
            } header: {
                Text("Account Info")
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Edit Profile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button {
                    Task {
                        await viewModel.saveProfile()
                        dismiss()
                    }
                } label: {
                    if viewModel.isSaving {
                        ProgressView()
                    } else {
                        Text("Save")
                            .fontWeight(.semibold)
                    }
                }
                .disabled(viewModel.isSaving)
            }
        }
        .onChange(of: selectedItem) { _, newValue in
            Task {
                if let data = try? await newValue?.loadTransferable(type: Data.self) {
                    viewModel.avatarImageData = data
                }
            }
        }
    }

    private var hasAvatar: Bool {
        viewModel.avatarImageData != nil || appState.currentUser?.avatarURL != nil
    }

    @ViewBuilder
    private var avatarView: some View {
        if let data = viewModel.avatarImageData, let uiImage = UIImage(data: data) {
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 100, height: 100)
                .clipShape(Circle())
        } else if let urlString = appState.currentUser?.avatarURL, let url = URL(string: urlString) {
            Color(.tertiarySystemGroupedBackground)
                .frame(width: 100, height: 100)
                .overlay {
                    AsyncImage(url: url) { phase in
                        if let image = phase.image {
                            image.resizable().aspectRatio(contentMode: .fill)
                        } else if phase.error != nil {
                            avatarPlaceholder
                        } else {
                            ProgressView()
                        }
                    }
                    .allowsHitTesting(false)
                }
                .clipShape(Circle())
        } else {
            avatarPlaceholder
        }
    }

    private var avatarPlaceholder: some View {
        Circle()
            .fill(Color.teal.opacity(0.15))
            .frame(width: 100, height: 100)
            .overlay {
                Image(systemName: "person.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(.teal)
            }
    }
}
