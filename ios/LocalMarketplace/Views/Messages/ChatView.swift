import SwiftUI

struct ChatView: View {
    let conversationID: String?
    let otherUserID: String
    let otherUserName: String
    let appState: AppState

    @State private var viewModel: MessagesViewModel
    @State private var showReportSheet = false
    @State private var showBlockAlert = false

    init(conversationID: String?, otherUserID: String, otherUserName: String, appState: AppState) {
        self.conversationID = conversationID
        self.otherUserID = otherUserID
        self.otherUserName = otherUserName
        self.appState = appState
        _viewModel = State(initialValue: MessagesViewModel(appState: appState))
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(viewModel.messages) { message in
                            MessageBubble(
                                message: message,
                                isCurrentUser: viewModel.isCurrentUser(message.senderID)
                            )
                            .id(message.id)
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
        .task {
            if let id = conversationID {
                await viewModel.loadMessages(conversationID: id)
            }
        }
        .sheet(isPresented: $showReportSheet) {
            ReportSheetView(reportedUserID: otherUserID, conversationID: conversationID, appState: appState)
        }
        .alert("Block User?", isPresented: $showBlockAlert) {
            Button("Block", role: .destructive) {
                appState.showToast("User blocked")
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
                    await viewModel.sendMessage(conversationID: conversationID ?? "new-\(otherUserID)")
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
