import Foundation
import CoreLocation

@Observable
@MainActor
class WantedBoardViewModel {
    var feedCards: [WantedCard] = []
    var myCards: [WantedCard] = []
    var isLoading: Bool = false
    var searchText: String = ""
    var radiusKm: Double = UserDefaults.standard.double(forKey: "wantedBoardRadius") == 0 ? 50.0 : UserDefaults.standard.double(forKey: "wantedBoardRadius")

    private let appState: AppState
    private let locationService: LocationService

    init(appState: AppState, locationService: LocationService) {
        self.appState = appState
        self.locationService = locationService
    }

    var filteredFeedCards: [WantedCard] {
        let userCoord = locationService.userLocation ?? LocationService.torontoCenter
        let currentUserID = appState.currentUser?.id ?? ""

        var cards = feedCards
            .filter { $0.userID != currentUserID }
            .filter { $0.distance(from: userCoord) <= radiusKm }
            .sorted { $0.distance(from: userCoord) < $1.distance(from: userCoord) }

        if !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let query = searchText.lowercased()
            cards = cards.filter {
                $0.tcgCardName.lowercased().contains(query) ||
                $0.tcgCardSetName.lowercased().contains(query) ||
                $0.tcgCardNumber.lowercased().contains(query)
            }
        }

        return cards
    }

    func myCardForSlot(_ index: Int) -> WantedCard? {
        myCards.first { $0.slotIndex == index }
    }

    func loadFeed() async {
        isLoading = true
        defer { isLoading = false }

        if appState.isMockMode { return }

        do {
            feedCards = try await SupabaseService.shared.fetchWantedCards()
        } catch {
            appState.showToast("Failed to load wanted board", isError: true)
        }
    }

    func loadMyBoard() async {
        guard let user = appState.currentUser else { return }

        if appState.isMockMode { return }

        do {
            myCards = try await SupabaseService.shared.fetchMyWantedCards(userID: user.id)
        } catch {
            appState.showToast("Failed to load your board", isError: true)
        }
    }

    func saveWantedCard(
        existingID: String?,
        slotIndex: Int,
        card: TCGCard,
        bidPrice: Double,
        conditions: Set<CardConditionOption>,
        gradingCompany: SlabCompany?,
        grades: Set<GradeValue>,
        notes: String?
    ) async -> Bool {
        guard let user = appState.currentUser else { return false }
        let coord = locationService.userLocation ?? LocationService.torontoCenter

        let conditionStrings = conditions.map(\.rawValue)
        let gradeStrings = conditions.contains(.Graded) ? grades.map(\.rawValue) : nil
        let company = conditions.contains(.Graded) ? gradingCompany?.rawValue : nil

        let wantedCard = WantedCard(
            id: existingID ?? UUID().uuidString,
            userID: user.id,
            slotIndex: slotIndex,
            tcgCardID: card.id,
            tcgCardName: card.name,
            tcgCardImageURL: card.imageLarge.isEmpty ? card.imageSmall : card.imageLarge,
            tcgCardNumber: card.number,
            tcgCardSetName: card.setName,
            bidPrice: bidPrice,
            conditions: conditionStrings,
            gradingCompany: company,
            grades: gradeStrings,
            notes: notes?.isEmpty == true ? nil : notes,
            latitude: coord.latitude,
            longitude: coord.longitude,
            createdAt: existingID != nil ? nil : Date(),
            updatedAt: Date()
        )

        do {
            if existingID != nil {
                try await SupabaseService.shared.updateWantedCard(wantedCard)
            } else {
                try await SupabaseService.shared.createWantedCard(wantedCard)
            }
            await loadMyBoard()
            await loadFeed()
            appState.showToast(existingID != nil ? "Listing updated" : "Listing created")
            return true
        } catch {
            appState.showToast("Failed to save listing", isError: true)
            return false
        }
    }

    func deleteWantedCard(id: String) async {
        do {
            try await SupabaseService.shared.deleteWantedCard(id: id)
            myCards.removeAll { $0.id == id }
            feedCards.removeAll { $0.id == id }
            appState.showToast("Listing removed")
        } catch {
            appState.showToast("Failed to delete listing", isError: true)
        }
    }

    func updateRadius(_ value: Double) {
        radiusKm = value
        UserDefaults.standard.set(value, forKey: "wantedBoardRadius")
    }

    func distanceString(for card: WantedCard) -> String {
        let coord = locationService.userLocation ?? LocationService.torontoCenter
        let km = card.distance(from: coord)
        if km < 1 {
            return "< 1 km away"
        }
        return "\(Int(km)) km away"
    }

    func sendMessageToOwner(card: WantedCard, messageText: String) async {
        guard let user = appState.currentUser, !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        guard user.id != card.userID else { return }

        do {
            let conversation = try await SupabaseService.shared.fetchOrCreateConversation(currentUserID: user.id, otherUserID: card.userID)
            let message = Message(
                id: UUID().uuidString,
                conversationID: conversation.id,
                senderID: user.id,
                body: messageText.trimmingCharacters(in: .whitespacesAndNewlines),
                createdAt: Date()
            )
            try await SupabaseService.shared.sendMessage(message)
            appState.showToast("Message sent!")
        } catch {
            appState.showToast("Failed to send message", isError: true)
        }
    }
}
