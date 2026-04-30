import SwiftUI

struct ChatView: View {
    let otherUserID: String
    let otherUserName: String
    let appState: AppState

    @State private var viewModel: MessagesViewModel
    @State private var activeConversationID: String?
    @State private var showReportSheet = false
    @State private var showBlockAlert = false
    @Environment(\.dismiss) private var dismiss

    init(conversationID: String?, otherUserID: String, otherUserName: String, appState: AppState) {
        self.otherUserID = otherUserID
        self.otherUserName = otherUserName
        self.appState = appState
        _viewModel = State(initialValue: MessagesViewModel(appState: appState))
        _activeConversationID = State(initialValue: conversationID)
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(viewModel.messages) { message in
                            if message.isInquiry, let inquiry = message.inquiryData {
                                InquiryMessageBubble(
                                    inquiry: inquiry,
                                    isCurrentUser: viewModel.isCurrentUser(message.senderID)
                                )
                                .id(message.id)
                            } else {
                                MessageBubble(
                                    message: message,
                                    isCurrentUser: viewModel.isCurrentUser(message.senderID)
                                )
                                .id(message.id)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                .onChange(of: viewModel.messages.count) { _, _ in
                    if let last = viewModel.messages.last {
                        withAnimation {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }
            }

            if viewModel.messages.isEmpty && !viewModel.isLoading {
                Spacer()
                VStack(spacing: 8) {
                    Image(systemName: "bubble.left.and.bubble.right")
                        .font(.system(size: 36))
                        .foregroundStyle(.secondary)
                    Text("Start the conversation")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }

            messageInput
        }
        .navigationTitle(otherUserName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button(role: .destructive) { showBlockAlert = true } label: {
                        Label("Block User", systemImage: "hand.raised.fill")
                    }
                    Button { showReportSheet = true } label: {
                        Label("Report", systemImage: "flag.fill")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .task(id: activeConversationID) {
            if let id = activeConversationID {
                await viewModel.loadMessages(conversationID: id)
            }
        }
        .sheet(isPresented: $showReportSheet) {
            ReportSheetView(reportedUserID: otherUserID, conversationID: activeConversationID, appState: appState)
        }
        .alert("Block User?", isPresented: $showBlockAlert) {
            Button("Block", role: .destructive) {
                guard let currentUser = appState.currentUser else { return }
                Task {
                    do {
                        try await SupabaseService.shared.blockUser(blockerID: currentUser.id, blockedID: otherUserID)
                        appState.addBlockedUserID(otherUserID)
                        appState.showToast("User blocked")
                        dismiss()
                    } catch {
                        appState.showToast("Failed to block user", isError: true)
                    }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("You won't be able to send or receive messages from this user.")
        }
    }

    private var messageInput: some View {
        HStack(spacing: 10) {
            TextField("Message...", text: Binding(
                get: { viewModel.messageText },
                set: { viewModel.messageText = $0 }
            ), axis: .vertical)
                .lineLimit(1...4)
                .padding(12)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(.rect(cornerRadius: 20))

            Button {
                Task {
                    if activeConversationID == nil {
                        let conversation = await viewModel.startConversation(with: otherUserID)
                        activeConversationID = conversation?.id
                    }

                    let messageConversationID = activeConversationID ?? "new-\(otherUserID)"
                    await viewModel.sendMessage(conversationID: messageConversationID)
                }
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title)
                    .foregroundStyle(.teal)
            }
            .disabled(viewModel.messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.bar)
    }
}

struct MessageBubble: View {
    let message: Message
    let isCurrentUser: Bool

    var body: some View {
        HStack {
            if isCurrentUser { Spacer(minLength: 60) }

            VStack(alignment: isCurrentUser ? .trailing : .leading, spacing: 4) {
                Text(message.body)
                    .font(.body)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(isCurrentUser ? Color.teal : Color(.secondarySystemGroupedBackground))
                    .foregroundStyle(isCurrentUser ? .white : .primary)
                    .clipShape(.rect(cornerRadius: 18))

                if let date = message.createdAt {
                    Text(date, style: .time)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }

            if !isCurrentUser { Spacer(minLength: 60) }
        }
    }
}
