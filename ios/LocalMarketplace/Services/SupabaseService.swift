import Foundation

@Observable
@MainActor
class SupabaseService {
    static let shared = SupabaseService()

    private let client = SupabaseClient.shared
    private let encoder = SupabaseClient.jsonEncoder
    private let decoder = SupabaseClient.jsonDecoder

    var isConfigured: Bool { client.isConfigured }

    func signUp(email: String, password: String, username: String, role: UserRole) async throws -> UserProfile {
        let result = try await client.signUp(email: email, password: password, metadata: ["username": username, "role": role.rawValue])

        let userID: String
        switch result {
        case .session(let session):
            userID = session.user.id
        case .userCreated(let id):
            userID = id
            _ = try await client.signIn(email: email, password: password)
        }

        let profile = UserProfile(id: userID, username: username, role: role, isDeleted: false, createdAt: Date())
        let body = try encoder.encode(profile)
        do {
            _ = try await client.insert("profiles", body: body)
        } catch {
            let existing: UserProfile? = try? await client.selectSingle("profiles", filters: ["id=eq.\(userID)"])
            if existing != nil { return existing! }
            throw error
        }
        return profile
    }

    func signIn(email: String, password: String) async throws -> UserProfile {
        let session = try await client.signIn(email: email, password: password)
        guard let profile: UserProfile = try await client.selectSingle("profiles", filters: ["id=eq.\(session.user.id)"]) else {
            throw SupabaseAPIError.httpError(404, "Profile not found")
        }
        return profile
    }

    func signOut() async throws {
        try await client.signOut()
    }

    func deleteAccount(userID: String) async throws {
        try await client.update("profiles", body: encoder.encode(["is_deleted": true]), filters: ["id=eq.\(userID)"])
    }

    func fetchProfile(userID: String) async throws -> UserProfile {
        guard let profile: UserProfile = try await client.selectSingle("profiles", filters: ["id=eq.\(userID)"]) else {
            throw SupabaseAPIError.httpError(404, "Profile not found")
        }
        return profile
    }

    func updateProfile(_ profile: UserProfile) async throws {
        let body = try encoder.encode(profile)
        try await client.update("profiles", body: body, filters: ["id=eq.\(profile.id)"])
    }

    func updateProfileFields(userID: String, displayName: String?, bio: String?, avatarURL: String?) async throws {
        var fields: [String: String] = [:]
        fields["display_name"] = displayName ?? ""
        fields["bio"] = bio ?? ""
        if let avatarURL {
            fields["avatar_url"] = avatarURL
        }
        let body = try JSONSerialization.data(withJSONObject: fields)
        try await client.update("profiles", body: body, filters: ["id=eq.\(userID)"])
    }

    func uploadImage(bucket: String, folder: String, imageData: Data) async throws -> String {
        let filename = "\(folder)/\(UUID().uuidString).jpg"
        return try await client.uploadFile(bucket: bucket, path: filename, data: imageData)
    }

    func uploadAvatar(userID: String, imageData: Data) async throws -> String {
        try await client.uploadFile(bucket: "avatars", path: "\(userID)/avatar.jpg", data: imageData)
    }

    func submitVendorApplication(_ application: VendorApplication) async throws {
        let body = try encoder.encode(application)
        _ = try await client.insert("vendor_applications", body: body)
    }

    func fetchVendorApplications(status: ApplicationStatus?) async throws -> [VendorApplication] {
        var filters: [String] = []
        if let status { filters.append("status=eq.\(status.rawValue)") }
        return try await client.select("vendor_applications", filters: filters, order: "created_at.desc")
    }

    func updateApplicationStatus(id: String, status: ApplicationStatus, note: String?) async throws {
        var updates: [String: String?] = ["status": status.rawValue]
        if let note { updates["admin_note"] = note }
        let body = try JSONSerialization.data(withJSONObject: updates.compactMapValues { $0 })
        try await client.update("vendor_applications", body: body, filters: ["id=eq.\(id)"])

        if status == .approved {
            let apps: [VendorApplication] = try await client.select("vendor_applications", filters: ["id=eq.\(id)"])
            if let app = apps.first {
                try await client.update("profiles", body: JSONSerialization.data(withJSONObject: ["role": "vendor"]), filters: ["id=eq.\(app.userID)"])
                let vendor = Vendor(userID: app.userID, storeName: "", categories: [], meetupAddress: "", approved: true, isDisabled: false, isActive: false)
                let vendorBody = try encoder.encode(vendor)
                _ = try await client.insert("vendors", body: vendorBody)
            }
        }
    }

    func fetchVendor(userID: String) async throws -> Vendor? {
        try await client.selectSingle("vendors", filters: ["user_id=eq.\(userID)"])
    }

    func updateVendor(_ vendor: Vendor) async throws {
        let body = try encoder.encode(vendor)
        try await client.update("vendors", body: body, filters: ["user_id=eq.\(vendor.userID)"])
    }

    func fetchActiveVendors() async throws -> [Vendor] {
        try await client.select("vendors", filters: ["approved=eq.true", "is_active=eq.true", "is_disabled=eq.false"])
    }

    func fetchBinders(vendorID: String) async throws -> [Binder] {
        try await client.select("binders", filters: ["vendor_id=eq.\(vendorID)"], order: "sort_order.asc")
    }

    func createBinder(_ binder: Binder) async throws {
        let body = try encoder.encode(binder)
        _ = try await client.insert("binders", body: body)
    }

    func updateBinder(_ binder: Binder) async throws {
        let body = try encoder.encode(binder)
        try await client.update("binders", body: body, filters: ["id=eq.\(binder.id)"])
    }

    func renameBinder(binderID: String, newName: String) async throws {
        let body = try JSONSerialization.data(withJSONObject: ["name": newName])
        try await client.update("binders", body: body, filters: ["id=eq.\(binderID)"])
    }

    func deleteBinder(id: String) async throws {
        try await client.delete("binders", filters: ["id=eq.\(id)"])
    }

    func fetchItems(vendorID: String) async throws -> [MarketplaceItem] {
        try await client.select("items", filters: ["vendor_id=eq.\(vendorID)"], order: "created_at.desc")
    }

    func createItem(_ item: MarketplaceItem) async throws {
        let body = try encoder.encode(item)
        _ = try await client.insert("items", body: body)
    }

    func updateItem(_ item: MarketplaceItem) async throws {
        let body = try encoder.encode(item)
        try await client.update("items", body: body, filters: ["id=eq.\(item.id)"])
    }

    func deleteItem(id: String) async throws {
        try await client.delete("items", filters: ["id=eq.\(id)"])
    }

    func fetchCardShows() async throws -> [CardShow] {
        try await client.select("card_shows", order: "event_date.asc")
    }

    func createCardShow(_ show: CardShow) async throws {
        let body = try encoder.encode(show)
        _ = try await client.insert("card_shows", body: body)
    }

    func updateCardShow(_ show: CardShow) async throws {
        let body = try encoder.encode(show)
        try await client.update("card_shows", body: body, filters: ["id=eq.\(show.id)"])
    }

    func deleteCardShow(id: String) async throws {
        try await client.delete("card_shows", filters: ["id=eq.\(id)"])
    }

    func fetchConversations(userID: String) async throws -> [Conversation] {
        let asP1: [Conversation] = try await client.select("conversations", filters: ["participant1_id=eq.\(userID)"], order: "updated_at.desc.nullslast")
        let asP2: [Conversation] = try await client.select("conversations", filters: ["participant2_id=eq.\(userID)"], order: "updated_at.desc.nullslast")

        var all = asP1
        for conv in asP2 {
            if !all.contains(where: { $0.id == conv.id }) { all.append(conv) }
        }

        var enriched: [Conversation] = []
        for var conv in all {
            let otherID = conv.otherParticipantID(currentUserID: userID)
            if let profile: UserProfile = try? await client.selectSingle("profiles", filters: ["id=eq.\(otherID)"]) {
                conv.otherUserName = profile.displayName ?? profile.username
                conv.otherUserAvatar = profile.avatarURL
            }
            let msgs: [Message] = try await client.select("messages", filters: ["conversation_id=eq.\(conv.id)"], order: "created_at.desc")
            conv.lastMessage = msgs.first
            enriched.append(conv)
        }
        return enriched.sorted { ($0.lastMessage?.createdAt ?? .distantPast) > ($1.lastMessage?.createdAt ?? .distantPast) }
    }

    func fetchOrCreateConversation(currentUserID: String, otherUserID: String) async throws -> Conversation {
        let asP1: [Conversation] = try await client.select("conversations", filters: ["participant1_id=eq.\(currentUserID)", "participant2_id=eq.\(otherUserID)"])
        if let conv = asP1.first { return conv }
        let asP2: [Conversation] = try await client.select("conversations", filters: ["participant1_id=eq.\(otherUserID)", "participant2_id=eq.\(currentUserID)"])
        if let conv = asP2.first { return conv }
        let newConv = Conversation(id: UUID().uuidString, participant1ID: currentUserID, participant2ID: otherUserID, createdAt: Date())
        let body = try encoder.encode(newConv)
        let responseData = try await client.insert("conversations", body: body)
        let created = try decoder.decode([Conversation].self, from: responseData)
        return created.first ?? newConv
    }

    func fetchMessages(conversationID: String) async throws -> [Message] {
        try await client.select("messages", filters: ["conversation_id=eq.\(conversationID)"], order: "created_at.asc")
    }

    func sendMessage(_ message: Message) async throws {
        let body = try encoder.encode(message)
        _ = try await client.insert("messages", body: body)
        let updateBody = try JSONSerialization.data(withJSONObject: ["updated_at": ISO8601DateFormatter().string(from: Date())])
        try? await client.update("conversations", body: updateBody, filters: ["id=eq.\(message.conversationID)"])
    }

    func followVendor(followerID: String, vendorID: String) async throws {
        let follow = Follow(id: UUID().uuidString, followerID: followerID, vendorID: vendorID, createdAt: Date())
        let body = try encoder.encode(follow)
        _ = try await client.insert("follows", body: body)
    }

    func unfollowVendor(followerID: String, vendorID: String) async throws {
        try await client.delete("follows", filters: ["follower_id=eq.\(followerID)", "vendor_id=eq.\(vendorID)"])
    }

    func fetchFollows(followerID: String) async throws -> [Follow] {
        try await client.select("follows", filters: ["follower_id=eq.\(followerID)"])
    }

    func blockUser(blockerID: String, blockedID: String) async throws {
        let block = Block(id: UUID().uuidString, blockerID: blockerID, blockedID: blockedID, createdAt: Date())
        let body = try encoder.encode(block)
        _ = try await client.insert("blocks", body: body)
    }

    func unblockUser(blockerID: String, blockedID: String) async throws {
        try await client.delete("blocks", filters: ["blocker_id=eq.\(blockerID)", "blocked_id=eq.\(blockedID)"])
    }

    func fetchBlocks(blockerID: String) async throws -> [Block] {
        try await client.select("blocks", filters: ["blocker_id=eq.\(blockerID)"])
    }

    func submitReport(_ report: Report) async throws {
        let body = try encoder.encode(report)
        _ = try await client.insert("reports", body: body)
    }

    func fetchReports(status: ReportStatus?) async throws -> [Report] {
        var filters: [String] = []
        if let status { filters.append("status=eq.\(status.rawValue)") }
        return try await client.select("reports", filters: filters, order: "created_at.desc")
    }

    func updateReportStatus(id: String, status: ReportStatus) async throws {
        let body = try JSONSerialization.data(withJSONObject: ["status": status.rawValue])
        try await client.update("reports", body: body, filters: ["id=eq.\(id)"])
    }

    func disableVendor(userID: String) async throws {
        let body = try JSONSerialization.data(withJSONObject: ["is_disabled": true])
        try await client.update("vendors", body: body, filters: ["user_id=eq.\(userID)"])
    }

    func promoteToAdmin(userID: String) async throws {
        let body = try JSONSerialization.data(withJSONObject: ["role": "admin"])
        try await client.update("profiles", body: body, filters: ["id=eq.\(userID)"])
    }

    func searchUsers(query: String) async throws -> [UserProfile] {
        try await client.select("profiles", filters: ["username=ilike.*\(query)*"])
    }

    func fetchWantedCards() async throws -> [WantedCard] {
        var cards: [WantedCard] = try await client.select("wanted_cards", order: "created_at.desc")
        for i in cards.indices {
            if let profile: UserProfile = try? await client.selectSingle("profiles", filters: ["id=eq.\(cards[i].userID)"]) {
                cards[i].ownerUsername = profile.displayName ?? profile.username
                cards[i].ownerAvatarURL = profile.avatarURL
            }
        }
        return cards
    }

    func fetchMyWantedCards(userID: String) async throws -> [WantedCard] {
        try await client.select("wanted_cards", filters: ["user_id=eq.\(userID)"], order: "slot_index.asc")
    }

    func createWantedCard(_ card: WantedCard) async throws {
        let body = try encoder.encode(card)
        _ = try await client.insert("wanted_cards", body: body)
    }

    func updateWantedCard(_ card: WantedCard) async throws {
        let body = try encoder.encode(card)
        try await client.update("wanted_cards", body: body, filters: ["id=eq.\(card.id)"])
    }

    func deleteWantedCard(id: String) async throws {
        try await client.delete("wanted_cards", filters: ["id=eq.\(id)"])
    }

    func updateNotificationPrefs(_ prefs: NotificationPrefs) async throws {
        let body = try encoder.encode(prefs)
        do {
            _ = try await client.insert("notification_prefs", body: body)
        } catch {
            try await client.update("notification_prefs", body: body, filters: ["user_id=eq.\(prefs.userID)"])
        }
    }

    func fetchNotificationPrefs(userID: String) async throws -> NotificationPrefs? {
        try await client.selectSingle("notification_prefs", filters: ["user_id=eq.\(userID)"])
    }
}
