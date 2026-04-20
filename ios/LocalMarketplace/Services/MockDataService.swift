import Foundation

@Observable
@MainActor
class MockDataService {
    static let shared = MockDataService()

    let mockUsers: [UserProfile] = [
        UserProfile(id: "buyer-1", username: "alex_collector", avatarURL: nil, role: .buyer, isDeleted: false),
        UserProfile(id: "buyer-2", username: "card_hunter", avatarURL: nil, role: .buyer, isDeleted: false),
        UserProfile(id: "vendor-1", username: "maple_cards", avatarURL: nil, role: .vendor, isDeleted: false),
        UserProfile(id: "vendor-2", username: "toronto_singles", avatarURL: nil, role: .vendor, isDeleted: false),
        UserProfile(id: "vendor-3", username: "slab_city", avatarURL: nil, role: .vendor, isDeleted: false),
        UserProfile(id: "vendor-4", username: "poke_vault", avatarURL: nil, role: .vendor, isDeleted: false),
        UserProfile(id: "vendor-5", username: "retro_gems", avatarURL: nil, role: .vendor, isDeleted: false),
        UserProfile(id: "admin-1", username: "admin", avatarURL: nil, role: .admin, isDeleted: false),
    ]

    var mockVendors: [Vendor] = [
        Vendor(userID: "vendor-1", storeName: "Maple Cards", bio: "Premium trading cards and collectibles. Specializing in hockey and basketball singles.", categories: ["Singles", "Slabs"], meetupAddress: "100 Queen St W, Toronto, ON", meetupSpotNote: "By the main entrance", profileImageURL: nil, coverImageURL: nil, lat: 43.6525, lng: -79.3832, approved: true, isDisabled: false, isActive: true, activeUntil: Date().addingTimeInterval(4 * 3600)),
        Vendor(userID: "vendor-2", storeName: "Toronto Singles", bio: "Your go-to source for raw singles. Baseball, football, and hockey.", categories: ["Singles", "Accessories"], meetupAddress: "220 Yonge St, Toronto, ON", meetupSpotNote: "Eaton Centre food court", profileImageURL: nil, coverImageURL: nil, lat: 43.6544, lng: -79.3807, approved: true, isDisabled: false, isActive: true, activeUntil: Date().addingTimeInterval(6 * 3600)),
        Vendor(userID: "vendor-3", storeName: "Slab City", bio: "PSA and BGS graded cards. Only authenticated slabs.", categories: ["Slabs"], meetupAddress: "300 Borough Dr, Scarborough, ON", meetupSpotNote: "Near Starbucks", profileImageURL: nil, coverImageURL: nil, lat: 43.7735, lng: -79.2577, approved: true, isDisabled: false, isActive: true, activeUntil: Date().addingTimeInterval(8 * 3600)),
        Vendor(userID: "vendor-4", storeName: "Poke Vault", bio: "Sealed Pokemon products and rare singles.", categories: ["Sealed", "Singles"], meetupAddress: "3401 Dufferin St, Toronto, ON", meetupSpotNote: nil, profileImageURL: nil, coverImageURL: nil, lat: 43.7276, lng: -79.4494, approved: true, isDisabled: false, isActive: false, activeUntil: nil),
        Vendor(userID: "vendor-5", storeName: "Retro Gems", bio: "Vintage sports cards from the 80s and 90s.", categories: ["Singles", "Accessories"], meetupAddress: "1 Dundas St W, Toronto, ON", meetupSpotNote: "Main floor near info desk", profileImageURL: nil, coverImageURL: nil, lat: 43.6561, lng: -79.3802, approved: false, isDisabled: false, isActive: false, activeUntil: nil),
    ]

    let mockApplications: [VendorApplication] = [
        VendorApplication(id: "app-1", userID: "vendor-5", status: .pending, contactEmail: "retro@example.com", contactPhone: "416-555-0199", answersJSON: ["experience": "10 years collecting vintage sports cards", "why_sell": "Downsizing my collection", "source": "Personal collection and estate sales"], adminNote: nil),
    ]

    let mockBinders: [Binder] = [
        Binder(id: "binder-1", vendorID: "vendor-1", name: "Hockey Hits", sortOrder: 0),
        Binder(id: "binder-2", vendorID: "vendor-1", name: "Basketball Stars", sortOrder: 1),
        Binder(id: "binder-3", vendorID: "vendor-2", name: "Baseball Classics", sortOrder: 0),
        Binder(id: "binder-4", vendorID: "vendor-3", name: "PSA 10 Club", sortOrder: 0),
        Binder(id: "binder-5", vendorID: "vendor-4", name: "Sealed Products", sortOrder: 0),
        Binder(id: "binder-6", vendorID: "vendor-4", name: "Rare Singles", sortOrder: 1),
    ]

    let mockItems: [MarketplaceItem] = [
        MarketplaceItem(id: "item-1", vendorID: "vendor-1", binderID: "binder-1", name: "Pikachu VMAX 44", priceCAD: 450.00, category: .single, condition: .NM, note: "Pack fresh", status: .active, tcgCardID: "swsh4-44", tcgCardName: "Pikachu VMAX", tcgCardNumber: "44", tcgCardDisplay: "Pikachu VMAX 44", tcgCardImageURL: "https://assets.tcgdex.net/en/swsh/swsh4/44/high.png", quantity: 2),
        MarketplaceItem(id: "item-2", vendorID: "vendor-1", binderID: "binder-1", name: "Charizard VMAX 20", priceCAD: 275.00, category: .single, condition: .LP, note: "Light corner wear", status: .active, image1URL: "https://placehold.co/400x560/2dd4bf/white?text=Front", image2URL: "https://placehold.co/400x560/3b82f6/white?text=Back", tcgCardID: "swsh35-20", tcgCardName: "Charizard VMAX", tcgCardNumber: "20", tcgCardDisplay: "Charizard VMAX 20", tcgCardImageURL: "https://assets.tcgdex.net/en/swsh/swsh3.5/20/high.png"),
        MarketplaceItem(id: "item-3", vendorID: "vendor-1", binderID: "binder-2", name: "Mew ex 151", priceCAD: 850.00, category: .single, condition: .NM, status: .active, tcgCardID: "sv3pt5-151", tcgCardName: "Mew ex", tcgCardNumber: "151", tcgCardDisplay: "Mew ex 151", tcgCardImageURL: "https://assets.tcgdex.net/en/sv/sv03.5/151/high.png"),
        MarketplaceItem(id: "item-4", vendorID: "vendor-2", binderID: "binder-3", name: "Umbreon VMAX 215", priceCAD: 125.00, category: .single, condition: .MP, status: .active, image1URL: "https://placehold.co/400x560/2dd4bf/white?text=Front", image2URL: "https://placehold.co/400x560/3b82f6/white?text=Back", tcgCardID: "swsh7-215", tcgCardName: "Umbreon VMAX", tcgCardNumber: "215", tcgCardDisplay: "Umbreon VMAX 215", tcgCardImageURL: "https://assets.tcgdex.net/en/swsh/swsh7/215/high.png"),
        MarketplaceItem(id: "item-5", vendorID: "vendor-3", binderID: "binder-4", name: "Charizard ex 199", priceCAD: 3500.00, category: .slab, note: "Gem mint", status: .active, tcgCardID: "sv2-199", tcgCardName: "Charizard ex", tcgCardNumber: "199", tcgCardDisplay: "Charizard ex 199", tcgCardImageURL: "https://assets.tcgdex.net/en/sv/sv02/199/high.png", slabGrade: 10, slabCompany: "PSA"),
        MarketplaceItem(id: "item-6", vendorID: "vendor-4", binderID: "binder-5", name: "Pokemon 151 Booster Box", priceCAD: 210.00, category: .sealed, status: .active, quantity: 3),
        MarketplaceItem(id: "item-7", vendorID: "vendor-4", binderID: "binder-6", name: "Mewtwo GX 31", priceCAD: 180.00, category: .single, condition: .NM, status: .active, tcgCardID: "sm2-31", tcgCardName: "Mewtwo-GX", tcgCardNumber: "31", tcgCardDisplay: "Mewtwo-GX 31", tcgCardImageURL: "https://assets.tcgdex.net/en/sm/sm2/31/high.png"),
        MarketplaceItem(id: "item-8", vendorID: "vendor-2", binderID: "binder-3", name: "Card Sleeves 100pk", priceCAD: 8.00, category: .accessory, status: .active, image1URL: "https://placehold.co/400x560/2dd4bf/white?text=Sleeves"),
        MarketplaceItem(id: "item-9", vendorID: "vendor-3", binderID: "binder-4", name: "Lugia V 186", priceCAD: 1200.00, category: .slab, note: "Beautiful centering", status: .active, tcgCardID: "swsh11-186", tcgCardName: "Lugia V", tcgCardNumber: "186", tcgCardDisplay: "Lugia V 186", tcgCardImageURL: "https://assets.tcgdex.net/en/swsh/swsh11/186/high.png", slabGrade: 9, slabCompany: "BGS"),
        MarketplaceItem(id: "item-10", vendorID: "vendor-1", binderID: "binder-1", name: "Eevee VMAX 18", priceCAD: 35.00, category: .single, condition: .NM, status: .sold, tcgCardID: "swsh7-18", tcgCardName: "Eevee VMAX", tcgCardNumber: "18", tcgCardDisplay: "Eevee VMAX 18", tcgCardImageURL: "https://assets.tcgdex.net/en/swsh/swsh7/18/high.png", soldAt: Date().addingTimeInterval(-86400)),
    ]

    let mockConversations: [Conversation] = [
        Conversation(id: "conv-1", participant1ID: "buyer-1", participant2ID: "vendor-1", createdAt: Date().addingTimeInterval(-86400), lastMessage: Message(id: "msg-3", conversationID: "conv-1", senderID: "vendor-1", body: "Yes, it's still available! Want to meet up?", createdAt: Date().addingTimeInterval(-3600)), otherUserName: "Maple Cards", otherUserAvatar: nil),
        Conversation(id: "conv-2", participant1ID: "buyer-1", participant2ID: "vendor-2", createdAt: Date().addingTimeInterval(-172800), lastMessage: Message(id: "msg-5", conversationID: "conv-2", senderID: "buyer-1", body: "Thanks for the quick deal!", createdAt: Date().addingTimeInterval(-7200)), otherUserName: "Toronto Singles", otherUserAvatar: nil),
    ]

    let mockMessages: [String: [Message]] = [
        "conv-1": [
            Message(id: "msg-1", conversationID: "conv-1", senderID: "buyer-1", body: "Hi! Is the Connor McDavid YG still available?", createdAt: Date().addingTimeInterval(-86400)),
            Message(id: "msg-2", conversationID: "conv-1", senderID: "buyer-1", body: "I'm interested in picking it up today if possible.", createdAt: Date().addingTimeInterval(-82800)),
            Message(id: "msg-3", conversationID: "conv-1", senderID: "vendor-1", body: "Yes, it's still available! Want to meet up?", createdAt: Date().addingTimeInterval(-3600)),
        ],
        "conv-2": [
            Message(id: "msg-4", conversationID: "conv-2", senderID: "buyer-1", body: "Hey, do you have any Jeter rookies?", createdAt: Date().addingTimeInterval(-172800)),
            Message(id: "msg-5", conversationID: "conv-2", senderID: "buyer-1", body: "Thanks for the quick deal!", createdAt: Date().addingTimeInterval(-7200)),
        ],
    ]

    var mockCardShows: [CardShow] = {
        let calendar = Calendar.current
        let day1 = calendar.startOfDay(for: Date().addingTimeInterval(10 * 24 * 3600))
        let day2 = calendar.date(byAdding: .day, value: 1, to: day1)!
        let day3 = calendar.date(byAdding: .day, value: 2, to: day1)!
        return [
            CardShow(
                id: "show-1",
                creatorVendorID: "vendor-1",
                title: "Toronto Pokemon Card Show",
                eventDescription: "Huge card show with vendors from across the GTA. Bring your binders and come trade! Sealed product giveaways every hour.",
                eventDate: Date().addingTimeInterval(3 * 24 * 3600),
                endTime: Date().addingTimeInterval(3 * 24 * 3600 + 6 * 3600),
                visibleOnMapDate: Date().addingTimeInterval(-2 * 24 * 3600),
                address: "Metro Toronto Convention Centre, 255 Front St W, Toronto, ON",
                lat: 43.6435,
                lng: -79.3871,
                mapImageURL: nil,
                posterImageURL: nil,
                attendeeVendorIDs: ["vendor-2", "vendor-3"],
                spotlightedVendorIDs: ["vendor-2"],
                createdAt: Date().addingTimeInterval(-2 * 24 * 3600)
            ),
            CardShow(
                id: "show-2",
                creatorVendorID: "vendor-2",
                title: "Scarborough Card Meetup",
                eventDescription: "Casual card meetup at STC. All collectors welcome. Singles, slabs, and sealed.",
                eventDate: Date().addingTimeInterval(5 * 24 * 3600),
                endTime: Date().addingTimeInterval(5 * 24 * 3600 + 5 * 3600),
                visibleOnMapDate: Date().addingTimeInterval(-1 * 24 * 3600),
                address: "Scarborough Town Centre, 300 Borough Dr, Scarborough, ON",
                lat: 43.7764,
                lng: -79.2318,
                mapImageURL: nil,
                posterImageURL: nil,
                attendeeVendorIDs: ["vendor-4"],
                spotlightedVendorIDs: [],
                createdAt: Date().addingTimeInterval(-1 * 24 * 3600)
            ),
            CardShow(
                id: "show-3",
                creatorVendorID: "vendor-3",
                title: "GTA Card Expo Weekend",
                eventDescription: "Three-day card expo featuring top vendors, live breaks, and exclusive giveaways. Don't miss the biggest event of the season!",
                eventDate: calendar.date(bySettingHour: 10, minute: 0, second: 0, of: day1)!,
                isMultiDay: true,
                daySchedules: [
                    EventDaySchedule(id: "sched-1", date: day1, startTime: calendar.date(bySettingHour: 10, minute: 0, second: 0, of: day1)!, endTime: calendar.date(bySettingHour: 18, minute: 0, second: 0, of: day1)!),
                    EventDaySchedule(id: "sched-2", date: day2, startTime: calendar.date(bySettingHour: 10, minute: 0, second: 0, of: day2)!, endTime: calendar.date(bySettingHour: 20, minute: 0, second: 0, of: day2)!),
                    EventDaySchedule(id: "sched-3", date: day3, startTime: calendar.date(bySettingHour: 11, minute: 0, second: 0, of: day3)!, endTime: calendar.date(bySettingHour: 16, minute: 0, second: 0, of: day3)!),
                ],
                visibleOnMapDate: Date().addingTimeInterval(-3 * 24 * 3600),
                address: "International Centre, 6900 Airport Rd, Mississauga, ON",
                lat: 43.6777,
                lng: -79.6248,
                attendeeVendorIDs: ["vendor-1", "vendor-2", "vendor-4"],
                spotlightedVendorIDs: ["vendor-1"],
                createdAt: Date().addingTimeInterval(-5 * 24 * 3600)
            ),
        ]
    }()

    let mockReports: [Report] = [
        Report(id: "report-1", reporterID: "buyer-2", reportedUserID: nil, reportedVendorID: "vendor-2", conversationID: nil, reason: "Suspicious pricing", details: "Listed a common card for way above market value", status: .open),
    ]

    func activeVendors() -> [Vendor] {
        mockVendors.filter { $0.approved && $0.isActive && !$0.isDisabled && !$0.isExpired }
    }

    func vendorItems(vendorID: String) -> [MarketplaceItem] {
        mockItems.filter { $0.vendorID == vendorID }
    }

    func vendorBinders(vendorID: String) -> [Binder] {
        mockBinders.filter { $0.vendorID == vendorID }.sorted { $0.sortOrder < $1.sortOrder }
    }

    func user(for id: String) -> UserProfile? {
        mockUsers.first { $0.id == id }
    }

    func vendor(for id: String) -> Vendor? {
        mockVendors.first { $0.userID == id }
    }

    func addCardShow(_ show: CardShow) {
        mockCardShows.append(show)
    }

    func updateCardShow(_ show: CardShow) {
        if let index = mockCardShows.firstIndex(where: { $0.id == show.id }) {
            mockCardShows[index] = show
        }
    }

    func updateVendor(_ vendor: Vendor) {
        if let index = mockVendors.firstIndex(where: { $0.userID == vendor.userID }) {
            mockVendors[index] = vendor
        }
    }
}
