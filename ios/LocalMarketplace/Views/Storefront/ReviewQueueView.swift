import SwiftUI
import PhotosUI

struct ReviewQueueView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var queuedItems: [QueuedItem]
    let vendorID: String
    let appState: AppState
    let onComplete: () -> Void

    @State private var isPublishing = false
    @State private var publishedCount = 0
    @State private var inactivePublishCount = 0
    @State private var showPhotoWarning = false

    private var canPublish: Bool {
        !queuedItems.isEmpty && queuedItems.allSatisfy(\.isValid) && !isPublishing
    }

    private var hasNonNMItems: Bool {
        queuedItems.contains { $0.condition != .NM }
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
                    Button("Back") { dismiss() }
                        .disabled(isPublishing)
                }
            }
            .safeAreaInset(edge: .bottom) {
                publishBar
            }
            .alert("Some items need photos", isPresented: $showPhotoWarning) {
                Button("Publish Anyway") {
                    publishAll()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Items not in Near Mint condition should have photos. Items without photos will be marked as inactive until photos are added.")
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
                if hasNonNMItems {
                    showPhotoWarning = true
                } else {
                    publishAll()
                }
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
        inactivePublishCount = 0

        Task {
            for item in queuedItems {
                guard let price = item.priceValue, price > 0 else { continue }

                let itemID = UUID().uuidString
                var image1URL: String?
                var image2URL: String?

                if let data = item.image1Data, !appState.isMockMode {
                    do {
                        image1URL = try await SupabaseService.shared.uploadImage(bucket: "items", folder: itemID, imageData: data)
                    } catch {
                        isPublishing = false
                        appState.showToast("Failed to upload image", isError: true)
                        return
                    }
                }

                if let data = item.image2Data, !appState.isMockMode {
                    do {
                        image2URL = try await SupabaseService.shared.uploadImage(bucket: "items", folder: "\(itemID)/back", imageData: data)
                    } catch {
                        isPublishing = false
                        appState.showToast("Failed to upload image", isError: true)
                        return
                    }
                }

                // Non-NM cards need a front photo before customers can see them.
                let publishStatus: ItemStatus = item.condition != .NM && !item.hasPhotos ? .inactive : .active
                if publishStatus == .inactive {
                    inactivePublishCount += 1
                }

                let marketplaceItem = MarketplaceItem(
                    id: itemID,
                    vendorID: vendorID,
                    binderID: item.binderID,
                    name: item.card.name,
                    priceCAD: price,
                    category: .single,
                    condition: item.condition,
                    note: item.note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : item.note,
                    status: publishStatus,
                    image1URL: image1URL,
                    image2URL: image2URL,
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
            if inactivePublishCount > 0 {
                appState.showToast("\(inactivePublishCount) items published as inactive — add photos to activate")
            } else {
                appState.showToast("Published \(publishedCount) items")
            }
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

            if item.condition.requiresImages {
                HStack(spacing: 10) {
                    QueuePhotoPickerButton(label: "Front Photo", imageData: $item.image1Data)
                    QueuePhotoPickerButton(label: "Back Photo (optional)", imageData: $item.image2Data)
                }
            }

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

            TextField("Add a note (optional)...", text: $item.note, axis: .vertical)
                .lineLimit(1...3)
                .textFieldStyle(.roundedBorder)

            if item.condition.requiresImages && !item.hasPhotos {
                Text("Photos required for non-NM")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.orange)
            }
        }
        .padding(.vertical, 6)
        .padding(8)
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke(item.isValid ? Color.clear : Color.red, lineWidth: 1.5)
        }
    }
}

private struct QueuePhotoPickerButton: View {
    let label: String
    @Binding var imageData: Data?

    @State private var selectedItem: PhotosPickerItem?

    var body: some View {
        VStack(spacing: 8) {
            photoPreview

            PhotosPicker(selection: $selectedItem, matching: .images) {
                Label(label, systemImage: "photo.on.rectangle.angled")
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .tint(.teal)
            .onChange(of: selectedItem) { _, newValue in
                Task {
                    if let data = try? await newValue?.loadTransferable(type: Data.self) {
                        imageData = data
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private var photoPreview: some View {
        if let imageData, let uiImage = UIImage(data: imageData) {
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 54, height: 72)
                .clipShape(.rect(cornerRadius: 8))
        } else {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.tertiarySystemGroupedBackground))
                .frame(width: 54, height: 72)
                .overlay {
                    Image(systemName: "photo")
                        .foregroundStyle(.secondary)
                }
        }
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
