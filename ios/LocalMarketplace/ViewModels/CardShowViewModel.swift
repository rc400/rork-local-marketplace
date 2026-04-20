import Foundation
import CoreLocation

@Observable
@MainActor
class CardShowViewModel {
    var cardShows: [CardShow] = []
    var isLoading: Bool = false
    var selectedShow: CardShow?

    let appState: AppState

    init(appState: AppState) {
        self.appState = appState
    }

    func loadCardShows() async {
        isLoading = true
        defer { isLoading = false }

        if appState.isMockMode {
            cardShows = MockDataService.shared.mockCardShows
            return
        }

        do {
            cardShows = try await SupabaseService.shared.fetchCardShows()
        } catch {
            appState.showToast("Failed to load events", isError: true)
        }
    }

    var mapVisibleShows: [CardShow] {
        cardShows.filter { $0.shouldShowOnMap }
    }

    func createCardShow(
        id: String = UUID().uuidString,
        title: String,
        eventDescription: String,
        eventDate: Date,
        endTime: Date?,
        isMultiDay: Bool,
        daySchedules: [EventDaySchedule],
        visibleOnMapDate: Date? = nil,
        address: String,
        mapImageURL: String?,
        posterImageURL: String?
    ) async {
        guard let vendor = appState.currentVendor else { return }

        var lat: Double?
        var lng: Double?
        let geocoder = CLGeocoder()
        if let placemarks = try? await geocoder.geocodeAddressString(address),
           let location = placemarks.first?.location {
            lat = location.coordinate.latitude
            lng = location.coordinate.longitude
        }

        let show = CardShow(
            id: id,
            creatorVendorID: vendor.userID,
            title: title,
            eventDescription: eventDescription,
            eventDate: eventDate,
            endTime: endTime,
            isMultiDay: isMultiDay,
            daySchedules: daySchedules,
            visibleOnMapDate: visibleOnMapDate,
            address: address,
            lat: lat,
            lng: lng,
            mapImageURL: mapImageURL,
            posterImageURL: posterImageURL,
            attendeeVendorIDs: [],
            spotlightedVendorIDs: [],
            createdAt: Date()
        )

        if appState.isMockMode {
            MockDataService.shared.addCardShow(show)
            cardShows = MockDataService.shared.mockCardShows
        } else {
            do {
                try await SupabaseService.shared.createCardShow(show)
                await loadCardShows()
            } catch {
                appState.showToast("Failed to create event", isError: true)
                return
            }
        }
        appState.showToast("Limited Time Event created!")
    }

    func toggleAttendance(showID: String) {
        guard let vendor = appState.currentVendor else { return }
        guard let index = cardShows.firstIndex(where: { $0.id == showID }) else { return }

        if cardShows[index].attendeeVendorIDs.contains(vendor.userID) {
            cardShows[index].attendeeVendorIDs.removeAll { $0 == vendor.userID }
        } else {
            cardShows[index].attendeeVendorIDs.append(vendor.userID)
        }

        let updated = cardShows[index]
        if appState.isMockMode {
            MockDataService.shared.updateCardShow(updated)
        } else {
            Task {
                try? await SupabaseService.shared.updateCardShow(updated)
            }
        }
    }

    func removeAttendee(vendorID: String, from showID: String) {
        guard let index = cardShows.firstIndex(where: { $0.id == showID }) else { return }
        cardShows[index].attendeeVendorIDs.removeAll { $0 == vendorID }
        cardShows[index].spotlightedVendorIDs.removeAll { $0 == vendorID }

        let updated = cardShows[index]
        if appState.isMockMode {
            MockDataService.shared.updateCardShow(updated)
        } else {
            Task {
                try? await SupabaseService.shared.updateCardShow(updated)
            }
        }
        appState.showToast("Vendor removed from attendees")
    }

    func toggleSpotlight(vendorID: String, in showID: String) {
        guard let index = cardShows.firstIndex(where: { $0.id == showID }) else { return }
        if cardShows[index].spotlightedVendorIDs.contains(vendorID) {
            cardShows[index].spotlightedVendorIDs.removeAll { $0 == vendorID }
        } else {
            cardShows[index].spotlightedVendorIDs.append(vendorID)
        }

        let updated = cardShows[index]
        if appState.isMockMode {
            MockDataService.shared.updateCardShow(updated)
        } else {
            Task {
                try? await SupabaseService.shared.updateCardShow(updated)
            }
        }
    }

    func updateCardShowDetails(
        showID: String,
        title: String,
        eventDescription: String,
        eventDate: Date,
        endTime: Date?,
        isMultiDay: Bool,
        daySchedules: [EventDaySchedule],
        visibleOnMapDate: Date?,
        address: String,
        mapImageURL: String?,
        posterImageURL: String?
    ) async {
        guard let index = cardShows.firstIndex(where: { $0.id == showID }) else { return }

        var lat: Double?
        var lng: Double?
        if address != cardShows[index].address {
            let geocoder = CLGeocoder()
            if let placemarks = try? await geocoder.geocodeAddressString(address),
               let location = placemarks.first?.location {
                lat = location.coordinate.latitude
                lng = location.coordinate.longitude
            }
        } else {
            lat = cardShows[index].lat
            lng = cardShows[index].lng
        }

        cardShows[index].title = title
        cardShows[index].eventDescription = eventDescription
        cardShows[index].eventDate = eventDate
        cardShows[index].endTime = endTime
        cardShows[index].isMultiDay = isMultiDay
        cardShows[index].daySchedules = daySchedules
        cardShows[index].visibleOnMapDate = visibleOnMapDate
        cardShows[index].address = address
        cardShows[index].lat = lat
        cardShows[index].lng = lng
        cardShows[index].mapImageURL = mapImageURL
        cardShows[index].posterImageURL = posterImageURL

        let updated = cardShows[index]
        if appState.isMockMode {
            MockDataService.shared.updateCardShow(updated)
        } else {
            do {
                try await SupabaseService.shared.updateCardShow(updated)
            } catch {
                appState.showToast("Failed to update event", isError: true)
                return
            }
        }
        appState.showToast("Event updated!")
    }

    func isCreator(of show: CardShow) -> Bool {
        appState.currentVendor?.userID == show.creatorVendorID
    }

    func isAttending(_ show: CardShow) -> Bool {
        guard let vendor = appState.currentVendor else { return false }
        return show.attendeeVendorIDs.contains(vendor.userID)
    }

    func vendorProfile(for vendorID: String) -> Vendor? {
        if let current = appState.currentVendor, current.userID == vendorID {
            return current
        }
        if appState.isMockMode {
            return MockDataService.shared.vendor(for: vendorID)
        }
        return nil
    }

    func fetchVendorProfile(for vendorID: String) async -> Vendor? {
        if let current = appState.currentVendor, current.userID == vendorID {
            return current
        }
        if appState.isMockMode {
            return MockDataService.shared.vendor(for: vendorID)
        }
        return try? await SupabaseService.shared.fetchVendor(userID: vendorID)
    }
}
