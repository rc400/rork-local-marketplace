import SwiftUI

struct ProfileView: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel: ProfileViewModel
    @State private var showSettings = false
    @State private var showStorefront = false
    @State private var showWantedBoard = false
    @State private var vendorLocationService = LocationService()

    init(appState: AppState) {
        _viewModel = State(initialValue: ProfileViewModel(appState: appState))
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink {
                        EditProfileView(viewModel: viewModel)
                    } label: {
                        HStack(spacing: 16) {
                            profileAvatar
                                .frame(width: 68, height: 68)

                            VStack(alignment: .leading, spacing: 4) {
                                if let displayName = appState.currentUser?.displayName, !displayName.isEmpty {
                                    Text(displayName)
                                        .font(.title3.weight(.bold))
                                    Text("@\(appState.currentUser?.username ?? "")")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                } else {
                                    Text(appState.currentUser?.username ?? "User")
                                        .font(.title3.weight(.bold))
                                }

                                CategoryBadge(text: appState.currentRole.displayName)
                            }

                            Spacer(minLength: 0)
                        }
                        .padding(.vertical, 4)
                    }
                }

                if let bio = appState.currentUser?.bio, !bio.isEmpty {
                    Section {
                        Text(bio)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                if appState.currentRole == .vendor {
                    Section {
                        Button {
                            showStorefront = true
                        } label: {
                            Label("My Storefront", systemImage: "storefront.fill")
                        }

                        NavigationLink {
                            MyEventsView(appState: appState)
                        } label: {
                            Label("Limited Time Events", systemImage: "party.popper.fill")
                                .foregroundStyle(.green)
                        }

                        Button {
                            showWantedBoard = true
                        } label: {
                            Label("Wanted Cards", systemImage: "rectangle.stack.fill")
                                .foregroundStyle(.teal)
                        }

                        if let app = appState.vendorApplication {
                            HStack {
                                Label("Application Status", systemImage: "doc.text.fill")
                                Spacer()
                                Text(app.status.rawValue.capitalized)
                                    .font(.subheadline)
                                    .foregroundStyle(app.status == .approved ? .green : app.status == .rejected ? .red : .orange)
                            }
                        }
                    }
                }

                Section("Followed Vendors") {
                    if viewModel.followedVendors.isEmpty {
                        HStack {
                            Image(systemName: "heart")
                                .foregroundStyle(.secondary)
                            Text("No followed vendors yet")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        ForEach(viewModel.followedVendors) { vendor in
                            NavigationLink {
                                VendorStorefrontView(vendorID: vendor.userID, appState: appState)
                            } label: {
                                HStack(spacing: 10) {
                                    Circle()
                                        .fill(Color.teal.opacity(0.1))
                                        .frame(width: 36, height: 36)
                                        .overlay {
                                            Image(systemName: "storefront.fill")
                                                .font(.caption)
                                                .foregroundStyle(.teal)
                                        }
                                    Text(vendor.storeName)
                                        .font(.subheadline)
                                }
                            }
                        }
                    }
                }

                Section {
                    Button {
                        showSettings = true
                    } label: {
                        Label("Settings", systemImage: "gearshape.fill")
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Profile")
            .task {
                await viewModel.loadProfile()
            }
            .navigationDestination(isPresented: $showStorefront) {
                if let user = appState.currentUser {
                    VendorStorefrontView(vendorID: user.id, appState: appState)
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .sheet(isPresented: $showWantedBoard) {
                WantedBoardView(appState: appState, locationService: vendorLocationService)
            }
        }
    }

    @ViewBuilder
    private var profileAvatar: some View {
        if let urlString = appState.currentUser?.avatarURL, let url = URL(string: urlString) {
            Color(.tertiarySystemGroupedBackground)
                .frame(width: 68, height: 68)
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
            .frame(width: 68, height: 68)
            .overlay {
                Image(systemName: "person.fill")
                    .font(.title)
                    .foregroundStyle(.teal)
            }
    }
}
