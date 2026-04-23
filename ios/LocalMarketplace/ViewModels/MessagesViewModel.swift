import Foundation

@Observable
@MainActor
class MessagesViewModel {
    var conversations: [Conversation] = []
    var messages: [Message] = []
    var isLoading: Bool = false
    var messageText: String = ""

    private let appState: AppState

    init(appState: AppState) {
        self.appState = appState
    }

    func loadConversations() async {
        guard let user = appState.currentUser else { return }
        isLoading = true
        defer { isLoading = false }

        if appState.isMockMode {
            conversations = MockDataService.shared.mockConversations
            return
        }

        do {
            conversations = try await SupabaseService.shared.fetchConversations(userID: user.id)
        } catch {
            appState.showToast("Failed to load messages", isError: true)
        }
    }

    func loadMessages(conversationID: String) async {
        isLoading = true
        defer { isLoading = false }

        if appState.isMockMode {
            messages = MockDataService.shared.mockMessages[conversationID] ?? []
            return
        }

        do {
            messages = try await SupabaseService.shared.fetchMessages(conversationID: conversationID)
        } catch {
            appState.showToast("Failed to load messages", isError: true)
        }
    }

    func sendMessage(conversationID: String) async {
        guard let user = appState.currentUser, !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        var resolvedConversationID = conversationID

        if conversationID.hasPrefix("new-") {
            let otherUserID = String(conversationID.dropFirst(4))
            do {
                let conversation = try await SupabaseService.shared.fetchOrCreateConversation(currentUserID: user.id, otherUserID: otherUserID)
                resolvedConversationID = conversation.id
            } catch {
                appState.showToast("Failed to start conversation", isError: true)
                return
            }
        }

        let message = Message(
            id: UUID().uuidString,
            conversationID: resolvedConversationID,
            senderID: user.id,
            body: messageText.trimmingCharacters(in: .whitespacesAndNewlines),
            createdAt: Date()
        )

        messageText = ""
        messages.append(message)

        if !appState.isMockMode {
            do {
                try await SupabaseService.shared.sendMessage(message)
            } catch {
                appState.showToast("Failed to send message", isError: true)
            }
        }
    }

    func sendInquiry(otherUserID: String, cartMessage: String) async {
        guard let user = appState.currentUser else { return }

        if appState.isMockMode {
            let conv = Conversation(
                id: UUID().uuidString,
                participant1ID: user.id,
                participant2ID: otherUserID,
                createdAt: Date(),
                lastMessage: Message(id: UUID().uuidString, conversationID: "", senderID: user.id, body: cartMessage, createdAt: Date()),
                otherUserName: MockDataService.shared.vendor(for: otherUserID)?.storeName
            )
            conversations.insert(conv, at: 0)
            appState.showToast("Inquiry sent!")
            return
        }

        do {
            let conversation = try await SupabaseService.shared.fetchOrCreateConversation(currentUserID: user.id, otherUserID: otherUserID)
            let message = Message(id: UUID().uuidString, conversationID: conversation.id, senderID: user.id, body: cartMessage, createdAt: Date())
            try await SupabaseService.shared.sendMessage(message)
            appState.showToast("Inquiry sent!")
        } catch {
            appState.showToast("Failed to send inquiry", isError: true)
        }
    }

    func startConversation(with otherUserID: String) async -> Conversation? {
        guard let user = appState.currentUser else { return nil }

        do {
            let conversation = try await SupabaseService.shared.fetchOrCreateConversation(currentUserID: user.id, otherUserID: otherUserID)
            return conversation
        } catch {
            appState.showToast("Failed to start conversation", isError: true)
            return nil
        }
    }

    func isCurrentUser(_ senderID: String) -> Bool {
        appState.currentUser?.id == senderID
    }
}
