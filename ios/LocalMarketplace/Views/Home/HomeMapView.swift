import SwiftUI
import MapKit

struct HomeMapView: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel: HomeViewModel
    @State private var locationService = LocationService()
    @State private var showVendorPreview = false
    @State private var showCardShowPreview = false
    @State private var searchText = ""
    @State private var selectedStorefrontVendor: Vendor?
    @State private var cardShowViewModel: CardShowViewModel

    init(appState: AppState) {
        _viewModel = State(initialValue: HomeViewModel(appState: appState))
        _cardShowViewModel = State(initialValue: CardShowViewModel(appState: appState))
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                if viewModel.showListView {
                    vendorListView
                } else {
                    mapView
                }

                VStack(spacing: 0) {
                    if appState.currentRole == .vendor {
                        VendorActiveCard(appState: appState)
                            .padding(.horizontal, 16)
                            .padding(.top, 8)
                    }

                    if !locationService.isAuthorized {
                        locationPromptCard
                            .padding(.horizontal, 16)
                            .padding(.top, 8)
                    }
                }
            }
            .navigationTitle("Local")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        withAnimation(.snappy) {
                            viewModel.showListView.toggle()
                        }
                    } label: {
                        Image(systemName: viewModel.showListView ? "map.fill" : "list.bullet")
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search city or address")
            .onSubmit(of: .search) {
                Task {
                    if let coord = await locationService.geocodeAddress(searchText) {
                        viewModel.centerOnLocation(coord)
                    }
                }
            }
            .task {
                await viewModel.loadVendors()
                await cardShowViewModel.loadCardShows()
                locationService.requestPermission()
            }
            .onChange(of: locationService.isAuthorized) { _, authorized in
                if authorized, let loc = locationService.userLocation {
                    viewModel.centerOnLocation(loc)
                }
            }
            .sheet(isPresented: $showVendorPreview) {
                if let vendor = viewModel.selectedVendor {
                    VendorPreviewCard(vendor: vendor, appState: appState)
                        .presentationDetents([.fraction(0.35), .large])
                        .presentationDragIndicator(.visible)
                        .presentationContentInteraction(.scrolls)
                }
            }
            .sheet(isPresented: $showCardShowPreview) {
                if let show = viewModel.selectedCardShow {
                    CardShowPreviewCard(show: show, appState: appState, viewModel: cardShowViewModel)
                        .presentationDetents([.fraction(0.4), .large])
                        .presentationDragIndicator(.visible)
                        .presentationContentInteraction(.scrolls)
                }
            }
            .fullScreenCover(item: $selectedStorefrontVendor) { vendor in
                NavigationStack {
                    VendorStorefrontView(vendorID: vendor.userID, appState: appState)
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Close") {
                                    selectedStorefrontVendor = nil
                                }
                            }
                        }
                }
            }
            .onChange(of: selectedStorefrontVendor) { _, newValue in
                if newValue == nil {
                    Task { await viewModel.loadVendors() }
                }
            }
            .onChange(of: appState.currentVendor) { _, _ in
                Task { await viewModel.loadVendors() }
            }
        }
    }

    private var mapView: some View {
        Map(position: Binding(
            get: { viewModel.cameraPosition },
            set: { viewModel.cameraPosition = $0 }
        )) {
            ForEach(viewModel.filteredVendors) { vendor in
                if let lat = vendor.lat, let lng = vendor.lng {
                    Annotation(vendor.storeName, coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lng)) {
                        Button {
                            viewModel.selectedVendor = vendor
                            showVendorPreview = true
                        } label: {
                            VStack(spacing: 2) {
                                Image(systemName: "mappin.circle.fill")
                                    .font(.title)
                                    .foregroundStyle(.teal)
                                    .background(Circle().fill(.white).padding(-2))
                            }
                        }
                    }
                }
            }

            ForEach(viewModel.filteredCardShows) { show in
                if let lat = show.lat, let lng = show.lng {
                    Annotation(show.title, coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lng)) {
                        Button {
                            viewModel.selectedCardShow = show
                            showCardShowPreview = true
                        } label: {
                            CardShowMapPin(show: show)
                        }
                    }
                }
            }

            UserAnnotation()
        }
        .mapControls {
            MapUserLocationButton()
            MapCompass()
        }
    }

    private var vendorListView: some View {
        List {
            if !viewModel.filteredCardShows.isEmpty {
                Section("Limited Time Events") {
                    ForEach(viewModel.filteredCardShows) { show in
                        Button {
                            viewModel.selectedCardShow = show
                            showCardShowPreview = true
                        } label: {
                            CardShowListRow(show: show)
                        }
                    }
                }
            }

            if viewModel.filteredVendors.isEmpty && viewModel.filteredCardShows.isEmpty {
                ContentUnavailableView("Nothing Nearby", systemImage: "storefront", description: Text("Check back later for active vendors and Limited Time Events."))
            } else {
                Section("Active Vendors") {
                    ForEach(viewModel.filteredVendors) { vendor in
                        Button {
                            selectedStorefrontVendor = vendor
                        } label: {
                            VendorListRow(vendor: vendor)
                        }
                    }
                }
            }
        }
        .listStyle(.plain)
    }

    private var locationPromptCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "location.slash.fill")
                .font(.title3)
                .foregroundStyle(.orange)

            VStack(alignment: .leading, spacing: 2) {
                Text("Location not available")
                    .font(.subheadline.weight(.semibold))
                Text("Search for a city or address above")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(14)
        .background(.ultraThinMaterial, in: .rect(cornerRadius: 14))
    }
}

struct CardShowMapPin: View {
    let show: CardShow

    var body: some View {
        ZStack {
            if let mapURL = show.mapImageURL, let url = URL(string: mapURL) {
                Color(.tertiarySystemGroupedBackground)
                    .frame(width: 44, height: 44)
                    .overlay {
                        AsyncImage(url: url) { phase in
                            if let image = phase.image {
                                image.resizable().aspectRatio(contentMode: .fill)
                            } else {
                                Image(systemName: "party.popper.fill")
                                    .font(.title3)
                                    .foregroundStyle(.green)
                            }
                        }
                        .allowsHitTesting(false)
                    }
                    .clipShape(Circle())
                    .overlay {
                        Circle().stroke(Color.green, lineWidth: 3)
                    }
            } else {
                Circle()
                    .fill(Color.green.opacity(0.15))
                    .frame(width: 44, height: 44)
                    .overlay {
                        Image(systemName: "party.popper.fill")
                            .font(.title3)
                            .foregroundStyle(.green)
                    }
                    .overlay {
                        Circle().stroke(Color.green, lineWidth: 3)
                    }
            }

            if !show.isHappeningNow {
                VStack {
                    HStack {
                        Spacer()
                        Image(systemName: "clock.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(.white)
                            .padding(3)
                            .background(Color.orange, in: Circle())
                    }
                    Spacer()
                }
                .frame(width: 44, height: 44)
            }
        }
        .shadow(color: .green.opacity(0.3), radius: 4, y: 2)
    }
}

struct CardShowListRow: View {
    let show: CardShow

    var body: some View {
        HStack(spacing: 14) {
            Circle()
                .fill(Color.green.opacity(0.15))
                .frame(width: 48, height: 48)
                .overlay {
                    Image(systemName: "party.popper.fill")
                        .foregroundStyle(.green)
                }
                .overlay {
                    Circle().stroke(Color.green, lineWidth: 2)
                }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(show.title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    CategoryBadge(
                        text: show.statusLabel,
                        style: show.isHappeningNow ? .active : .standard
                    )
                }

                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Group {
                        if show.isMultiDay {
                            Text(show.dateDisplayString)
                        } else {
                            Text(show.eventDate, format: .dateTime.month(.abbreviated).day().hour().minute())
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            }

            Spacer()

            if !show.attendeeVendorIDs.isEmpty {
                HStack(spacing: 3) {
                    Image(systemName: "person.2.fill")
                        .font(.caption2)
                    Text("\(show.attendeeVendorIDs.count)")
                        .font(.caption.weight(.semibold))
                }
                .foregroundStyle(.green)
            }
        }
        .padding(.vertical, 4)
    }
}

struct VendorListRow: View {
    let vendor: Vendor

    var body: some View {
        HStack(spacing: 14) {
            if let profileURL = vendor.profileImageURL, let url = URL(string: profileURL) {
                Color(.tertiarySystemGroupedBackground)
                    .frame(width: 48, height: 48)
                    .overlay {
                        AsyncImage(url: url) { phase in
                            if let image = phase.image {
                                image.resizable().aspectRatio(contentMode: .fill)
                            } else {
                                Image(systemName: "storefront.fill")
                                    .foregroundStyle(.teal)
                            }
                        }
                        .allowsHitTesting(false)
                    }
                    .clipShape(Circle())
            } else {
                Circle()
                    .fill(Color.teal.opacity(0.15))
                    .frame(width: 48, height: 48)
                    .overlay {
                        Image(systemName: "storefront.fill")
                            .foregroundStyle(.teal)
                    }
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Text(vendor.storeName)
                        .font(.headline)
                    VerifiedBadge()
                }

                HStack(spacing: 6) {
                    ForEach(vendor.categories.prefix(3), id: \.self) { cat in
                        CategoryBadge(text: cat)
                    }
                }
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }
}
