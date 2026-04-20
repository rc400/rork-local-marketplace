import SwiftUI

struct InboxView: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel: MessagesViewModel

    init(appState: AppState) {
        _viewModel = State(initialValue: MessagesViewModel(appState: appState))
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.conversations.isEmpty && !viewModel.isLoading {
                    ContentUnavailableView("No Messages", systemImage: "message", description: Text("Start a conversation by browsing vendor stores or user profiles."))
                } else {
                    List(viewModel.conversations) { conversation in
                        NavigationLink {
                            ChatView(
                                conversationID: conversation.id,
                                otherUserID: conversation.otherParticipantID(currentUserID: appState.currentUser?.id ?? ""),
                                otherUserName: conversation.otherUserName ?? "User",
                                appState: appState
                            )
                        } label: {
                            ConversationRow(conversation: conversation, currentUserID: appState.currentUser?.id ?? "")
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Messages")
            .overlay {
                if viewModel.isLoading {
                    ProgressView()
                }
            }
            .task {
                await viewModel.loadConversations()
            }
            .refreshable {
                await viewModel.loadConversations()
            }
        }
    }
}

struct ConversationRow: View {
    let conversation: Conversation
    let currentUserID: String

    var body: some View {
        HStack(spacing: 14) {
            Circle()
                .fill(Color.teal.opacity(0.15))
                .frame(width: 50, height: 50)
                .overlay {
                    Image(systemName: "person.fill")
                        .foregroundStyle(.teal)
                }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(conversation.otherUserName ?? "User")
                        .font(.headline)

                    Spacer()

                    if let date = conversation.lastMessage?.createdAt {
                        Text(date, style: .relative)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                if let lastMessage = conversation.lastMessage {
                    Text(lastMessage.body)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .padding(.vertical, 4)
    }
}
