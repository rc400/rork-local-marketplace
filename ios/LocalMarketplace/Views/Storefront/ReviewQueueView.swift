import SwiftUI

struct ReviewQueueView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var queuedItems: [QueuedItem]
    let vendorID: String
    let appState: AppState
    let onComplete: () -> Void

    @State private var isPublishing = false
    @State private var publishedCount = 0

    private var canPublish: Bool {
        !queuedItems.isEmpty && queuedItems.allSatisfy(\.isValid) && !isPublishing
    }

    var body: some View {
        NavigationStack {
            List {
                if queuedItems.isEmpty {
                    ContentUnavailableView("Queue Empty", systemImage: "tray", description: Text("Add cards from Quick Add or Set Browse."))
                        .listRowBackground(Color.clear)
                } else {
                    ForEach($queuedItems) { $item in
                        ReviewQueueRow(item: $item)
                            .swipeActions {
                                Button(role: .destructive) {
                                    deleteItem(id: item.id)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                    .onDelete { offsets in
                        queuedItems.remove(atOffsets: offsets)
                    }
                }
            }
            .navigationTitle("Review Queue")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .disabled(isPublishing)
                }
            }
            .safeAreaInset(edge: .bottom) {
                publishBar
            }
        }
    }

    private var publishBar: some View {
        VStack(spacing: 10) {
            if isPublishing {
                ProgressView(value: Double(publishedCount), total: Double(max(queuedItems.count, 1)))
                Text("Publishing \(publishedCount)/\(queuedItems.count)...")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Button {
                publishAll()
            } label: {
                Label("Publish All", systemImage: "paperplane.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.teal)
            .disabled(!canPublish)
        }
        .padding(14)
        .background(.regularMaterial)
        .overlay(alignment: .top) {
            Divider()
        }
    }

    private func deleteItem(id: String) {
        queuedItems.removeAll { $0.id == id }
    }

    private func publishAll() {
        isPublishing = true
        publishedCount = 0

        Task {
            for item in queuedItems {
                guard let price = item.priceValue, price > 0 else { continue }

                let marketplaceItem = MarketplaceItem(
                    id: UUID().uuidString,
                    vendorID: vendorID,
                    binderID: item.binderID,
                    name: item.card.name,
                    priceCAD: price,
                    category: .single,
                    condition: item.condition,
                    status: .active,
                    tcgCardID: item.card.id,
                    tcgCardName: item.card.name,
                    tcgCardNumber: item.card.number,
                    tcgCardDisplay: item.card.displayName,
                    tcgCardImageURL: item.card.imageLarge.isEmpty ? item.card.imageSmall : item.card.imageLarge,
                    quantity: item.quantity
                )

                do {
                    if !appState.isMockMode {
                        try await SupabaseService.shared.createItem(marketplaceItem)
                    }
                    publishedCount += 1
                } catch {
                    isPublishing = false
                    appState.showToast("Failed to publish queue", isError: true)
                    return
                }
            }

            queuedItems.removeAll()
            isPublishing = false
            appState.showToast("Published \(publishedCount) items")
            onComplete()
        }
    }
}

private struct ReviewQueueRow: View {
    @Binding var item: QueuedItem

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                QueueCardThumbnail(card: item.card)

                VStack(alignment: .leading, spacing: 4) {
                    Text(item.card.displayName)
                        .font(.subheadline.weight(.semibold))
                    if !item.card.setName.isEmpty {
                        Text(item.card.setName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Text("\(item.condition.shortName) - $\(item.price) - Qty \(item.quantity)")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(item.isValid ? .teal : .orange)
                }
            }

            Picker("Condition", selection: $item.condition) {
                ForEach(ItemCondition.allCases, id: \.self) { condition in
                    Text(condition.shortName).tag(condition)
                }
            }
            .pickerStyle(.segmented)

            HStack(spacing: 12) {
                HStack(spacing: 4) {
                    Text("$")
                        .foregroundStyle(.secondary)
                    TextField("Price", text: $item.price)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(.plain)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 9)
                .background(Color(.tertiarySystemGroupedBackground))
                .clipShape(.rect(cornerRadius: 10))

                Stepper("Qty: \(item.quantity)", value: $item.quantity, in: 1...999)
            }
        }
        .padding(.vertical, 6)
    }
}

private struct QueueCardThumbnail: View {
    let card: TCGCard

    var body: some View {
        Group {
            if let url = card.smallImageURL {
                Color.clear
                    .aspectRatio(0.714, contentMode: .fit)
                    .frame(width: 48)
                    .overlay {
                        AsyncImage(url: url) { phase in
                            if let image = phase.image {
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                            } else if phase.error != nil {
                                placeholder
                            } else {
                                ProgressView()
                            }
                        }
                    }
            } else {
                placeholder
                    .frame(width: 48)
            }
        }
        .clipShape(.rect(cornerRadius: 5))
    }

    private var placeholder: some View {
        Color(.tertiarySystemGroupedBackground)
            .aspectRatio(0.714, contentMode: .fit)
            .overlay {
                Image(systemName: "rectangle.portrait.fill")
                    .foregroundStyle(.secondary)
            }
    }
}
