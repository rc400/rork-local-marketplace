import SwiftUI

struct ContentView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        ZStack {
            if appState.isAuthenticated {
                switch appState.currentRole {
                case .buyer:
                    BuyerTabView()
                case .vendor:
                    VendorTabView()
                case .admin:
                    AdminTabView()
                }
            } else {
                WelcomeView()
            }

            if let message = appState.toastMessage {
                VStack {
                    ToastView(message: message, isError: appState.toastIsError)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    Spacer()
                }
                .animation(.spring(duration: 0.4), value: appState.toastMessage)
                .zIndex(100)
            }
        }
    }
}

struct BuyerTabView: View {
    @Environment(AppState.self) private var appState
    @State private var selectedTab = 0
    @State private var buyerLocationService = LocationService()

    var body: some View {
        ZStack(alignment: .top) {
            TabView(selection: $selectedTab) {
                Tab("Home", systemImage: "map.fill", value: 0) {
                    HomeMapView(appState: appState)
                }

                Tab("Wanted Board", systemImage: "rectangle.stack.fill", value: 1) {
                    WantedBoardView(appState: appState, locationService: buyerLocationService)
                }

                Tab("Messages", systemImage: "message.fill", value: 2) {
                    InboxView(appState: appState)
                }

                Tab("Profile", systemImage: "person.fill", value: 3) {
                    ProfileView(appState: appState)
                }
            }
            .tint(.teal)

            if appState.showNewAccountBanner {
                NewAccountBanner {
                    withAnimation(.spring(duration: 0.3)) {
                        appState.showNewAccountBanner = false
                    }
                    selectedTab = 3
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .zIndex(99)
            }
        }
        .animation(.spring(duration: 0.4), value: appState.showNewAccountBanner)
    }
}

struct NewAccountBanner: View {
    let onGoToProfile: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "person.crop.circle.badge.plus")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.teal)

            VStack(alignment: .leading, spacing: 2) {
                Text("Welcome to Local!")
                    .font(.subheadline.weight(.semibold))
                Text("Head to your profile to add a photo & more.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)

            Button {
                onGoToProfile()
            } label: {
                Text("Go")
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(.teal, in: .capsule)
                    .foregroundStyle(.white)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, 16)
        .padding(.top, 4)
        .shadow(color: .black.opacity(0.08), radius: 8, y: 4)
    }
}

struct VendorTabView: View {
    @Environment(AppState.self) private var appState
    @State private var selectedTab = 0
    @State private var showCreateItem = false

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Home", systemImage: "map.fill", value: 0) {
                HomeMapView(appState: appState)
            }

            Tab("Storefront", systemImage: "storefront.fill", value: 1) {
                if let user = appState.currentUser {
                    NavigationStack {
                        VendorStorefrontView(vendorID: user.id, appState: appState)
                    }
                }
            }

            Tab("Create", systemImage: "plus.circle.fill", value: 2) {
                Color.clear
                    .onAppear {
                        showCreateItem = true
                        selectedTab = 1
                    }
            }

            Tab("Messages", systemImage: "message.fill", value: 3) {
                InboxView(appState: appState)
            }

            Tab("Profile", systemImage: "person.fill", value: 4) {
                ProfileView(appState: appState)
            }
        }
        .tint(.teal)
        .sheet(isPresented: $showCreateItem) {
            VendorCreateFlow(appState: appState)
        }
    }
}

struct AdminTabView: View {
    @Environment(AppState.self) private var appState
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Admin", systemImage: "shield.fill", value: 0) {
                AdminDashboardView(appState: appState)
            }

            Tab("Profile", systemImage: "person.fill", value: 1) {
                ProfileView(appState: appState)
            }
        }
        .tint(.teal)
    }
}

struct VendorCreateFlow: View {
    let appState: AppState
    @State private var viewModel: StorefrontViewModel

    init(appState: AppState) {
        self.appState = appState
        _viewModel = State(initialValue: StorefrontViewModel(appState: appState))
    }

    var body: some View {
        CreateItemView(viewModel: viewModel)
            .task {
                if let user = appState.currentUser {
                    await viewModel.loadStorefront(vendorID: user.id)
                }
            }
    }
}
