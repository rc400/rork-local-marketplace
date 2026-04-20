import SwiftUI

struct WantedCardDetailSheet: View {
    let card: WantedCard
    let viewModel: WantedBoardViewModel
    let appState: AppState

    @Environment(\.dismiss) private var dismiss
    @State private var messageText: String = ""
    @State private var isSending: Bool = false
    @State private var showReportSheet: Bool = false
    @State private var showMessageSentConfirmation: Bool = false

    private var isOwnCard: Bool {
        appState.currentUser?.id == card.userID
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 16) {
                        Color(.secondarySystemBackground)
                            .frame(height: 280)
                            .overlay {
                                AsyncImage(url: URL(string: card.tcgCardImageURL)) { phase in
                                    if let image = phase.image {
                                        image.resizable().aspectRatio(contentMode: .fit)
                                    } else if phase.error != nil {
                                        Image(systemName: "rectangle.portrait.slash")
                                            .font(.largeTitle)
                                            .foregroundStyle(.tertiary)
                                    } else {
                                        ProgressView()
                                    }
                                }
                                .allowsHitTesting(false)
                            }
                            .clipShape(.rect(cornerRadius: 12))

                        VStack(alignment: .leading, spacing: 10) {
                            HStack(alignment: .top) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(card.tcgCardName)
                                        .font(.title3.weight(.bold))
                                    Text("\(card.tcgCardSetName) · #\(card.tcgCardNumber)")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text("$\(card.bidPrice, specifier: "%.2f")")
                                    .font(.title2.weight(.bold))
                                    .foregroundStyle(.teal)
                            }

                            Divider()

                            detailRow(label: "Condition", value: card.conditionsDisplay)

                            if card.isGraded {
                                if let company = card.gradingCompany {
                                    detailRow(label: "Grading Co.", value: company)
                                }
                                if !card.gradesDisplay.isEmpty {
                                    detailRow(label: "Grade", value: card.gradesDisplay)
                                }
                            }

                            detailRow(label: "Distance", value: viewModel.distanceString(for: card))

                            if let owner = card.ownerUsername {
                                detailRow(label: "Posted by", value: owner)
                            }

                            if let notes = card.notes, !notes.isEmpty {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Notes")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(.secondary)
                                    Text(notes)
                                        .font(.subheadline)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                    .padding(.top, 16)
                }

                if !isOwnCard {
                    messageArea
                }
            }
            .navigationTitle("Wanted Listing")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
                if !isOwnCard {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button { showReportSheet = true } label: {
                            Image(systemName: "flag")
                        }
                    }
                }
            }
            .sheet(isPresented: $showReportSheet) {
                ReportSheetView(reportedUserID: card.userID, appState: appState)
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    private func detailRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(width: 90, alignment: .leading)
            Text(value)
                .font(.subheadline)
        }
    }

    private var messageArea: some View {
        HStack(spacing: 10) {
            TextField("Send a message...", text: $messageText, axis: .vertical)
                .lineLimit(1...3)
                .padding(12)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(.rect(cornerRadius: 20))

            Button {
                Task {
                    isSending = true
                    await viewModel.sendMessageToOwner(card: card, messageText: messageText)
                    messageText = ""
                    isSending = false
                    showMessageSentConfirmation = true
                }
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title)
                    .foregroundStyle(.teal)
            }
            .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSending)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.bar)
        .overlay {
            if showMessageSentConfirmation {
                VStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(.green)
                    Text("Message Sent")
                        .font(.subheadline.weight(.semibold))
                }
                .padding(20)
                .background(.ultraThinMaterial, in: .rect(cornerRadius: 16))
                .transition(.scale.combined(with: .opacity))
                .onAppear {
                    Task {
                        try? await Task.sleep(for: .seconds(1.5))
                        withAnimation { showMessageSentConfirmation = false }
                    }
                }
            }
        }
        .animation(.spring(duration: 0.3), value: showMessageSentConfirmation)
    }
}
