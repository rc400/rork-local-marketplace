import SwiftUI
import MapKit

@Observable
@MainActor
class HomeViewModel {
    var vendors: [Vendor] = []
    var cardShows: [CardShow] = []
    var selectedVendor: Vendor?
    var selectedCardShow: CardShow?
    var searchText: String = ""
    var showListView: Bool = false
    var isLoading: Bool = false
    var cameraPosition: MapCameraPosition = .region(MKCoordinateRegion(
        center: LocationService.torontoCenter,
        span: LocationService.defaultSpan
    ))

    private let appState: AppState

    init(appState: AppState) {
        self.appState = appState
    }

    func loadVendors() async {
        isLoading = true
        defer { isLoading = false }

        if appState.isMockMode {
            vendors = MockDataService.shared.activeVendors()
            cardShows = MockDataService.shared.mockCardShows.filter { $0.shouldShowOnMap }
        } else {
            do {
                vendors = try await SupabaseService.shared.fetchActiveVendors()
                let allShows = try await SupabaseService.shared.fetchCardShows()
                cardShows = allShows.filter { $0.shouldShowOnMap }
            } catch {
                appState.showToast("Failed to load vendors", isError: true)
            }
        }

        if let currentVendor = appState.currentVendor,
           let idx = vendors.firstIndex(where: { $0.userID == currentVendor.userID }) {
            vendors[idx] = currentVendor
        }
    }

    func checkVendorTimers() {
        for i in vendors.indices {
            if vendors[i].isExpired && vendors[i].isActive {
                vendors[i].isActive = false
            }
        }
    }

    var filteredVendors: [Vendor] {
        guard !searchText.isEmpty else { return vendors }
        return vendors.filter {
            $0.storeName.localizedStandardContains(searchText) ||
            $0.meetupAddress.localizedStandardContains(searchText) ||
            $0.categories.contains { $0.localizedStandardContains(searchText) }
        }
    }

    var filteredCardShows: [CardShow] {
        guard !searchText.isEmpty else { return cardShows }
        return cardShows.filter {
            $0.title.localizedStandardContains(searchText) ||
            $0.address.localizedStandardContains(searchText)
        }
    }

    func centerOnLocation(_ coordinate: CLLocationCoordinate2D) {
        cameraPosition = .region(MKCoordinateRegion(
            center: coordinate,
            span: LocationService.defaultSpan
        ))
    }
}
