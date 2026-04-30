import SwiftUI

struct EditItemView: View {
    @Environment(\.dismiss) private var dismiss
    let item: MarketplaceItem
    let viewModel: StorefrontViewModel
    let onSave: () -> Void

    @State private var priceText: String
    @State private var condition: ItemCondition
    @State private var quantity: Int
    @State private var note: String
    @State private var status: ItemStatus
    @State private var image1Data: Data?
    @State private var image2Data: Data?
    @State private var isSaving = false

    private var isValid: Bool {
        guard let price = Double(priceText), price > 0 else { return false }
        return quantity > 0
    }

    init(item: MarketplaceItem, viewModel: StorefrontViewModel, onSave: @escaping () -> Void) {
        self.item = item
        self.viewModel = viewModel
        self.onSave = onSave
        _priceText = State(initialValue: String(format: "%.2f", item.priceCAD))
        _condition = State(initialValue: item.condition ?? .NM)
        _quantity = State(initialValue: max(item.quantity, 1))
        _note = State(initialValue: item.note ?? "")
        _status = State(initialValue: item.status)
    }

    var body: some View {
        NavigationStack {
            Form {
                itemSummarySection
                pricingSection
                statusSection
                notesSection
                photoSection
            }
            .navigationTitle("Edit Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .disabled(isSaving)
                }
                ToolbarItem(placement: .confirmationAction) {
                    if isSaving {
                        ProgressView()
                    } else {
                        Button("Save") { saveItem() }
                            .disabled(!isValid)
                    }
                }
            }
        }
    }

    private var itemSummarySection: some View {
        Section("Listing") {
            HStack(spacing: 12) {
                itemThumbnail

                VStack(alignment: .leading, spacing: 4) {
                    Text(item.conditionPrefix + item.displayName)
                        .font(.subheadline.weight(.semibold))
                    Text(item.category.displayName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if let slabLabel = item.slabDisplayLabel {
                        Text(slabLabel)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private var itemThumbnail: some View {
        Color(.tertiarySystemGroupedBackground)
            .frame(width: 54, height: 72)
            .overlay {
                if let urlString = item.primaryImageURL, let url = URL(string: urlString) {
                    AsyncImage(url: url) { phase in
                        if let image = phase.image {
                            image.resizable().aspectRatio(contentMode: .fill)
                        } else {
                            Image(systemName: item.category.icon)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .allowsHitTesting(false)
                } else {
                    Image(systemName: item.category.icon)
                        .foregroundStyle(.secondary)
                }
            }
            .clipShape(.rect(cornerRadius: 8))
    }

    private var pricingSection: some View {
        Section(item.category.hasCondition ? "Pricing & Condition" : "Pricing") {
            TextField("Price (CAD)", text: $priceText)
                .keyboardType(.decimalPad)

            Stepper("Quantity: \(quantity)", value: $quantity, in: 1...999)

            if item.category.hasCondition {
                Picker("Condition", selection: $condition) {
                    ForEach(ItemCondition.allCases, id: \.self) { cond in
                        Text(cond.displayName).tag(cond)
                    }
                }
            }
        }
    }

    private var statusSection: some View {
        Section("Status") {
            Picker("Status", selection: $status) {
                Text("Active").tag(ItemStatus.active)
                Text("Inactive").tag(ItemStatus.inactive)
                Text("Sold").tag(ItemStatus.sold)
            }
            .pickerStyle(.segmented)
        }
    }

    private var notesSection: some View {
        Section("Note") {
            TextField("Note (optional)", text: $note, axis: .vertical)
                .lineLimit(2...4)
        }
    }

    private var photoSection: some View {
        Section("Photos") {
            ImagePickerButton(label: "Front Photo", currentURL: item.image1URL, imageData: $image1Data)
            ImagePickerButton(label: "Back Photo", currentURL: item.image2URL, imageData: $image2Data)
        }
    }

    private func saveItem() {
        guard let price = Double(priceText) else { return }
        isSaving = true

        Task {
            var updated = item
            updated.priceCAD = price
            updated.condition = item.category.hasCondition ? condition : item.condition
            updated.quantity = quantity
            updated.note = note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : note
            updated.status = status
            if status == .sold, updated.soldAt == nil {
                updated.soldAt = Date()
            } else if status != .sold {
                updated.soldAt = nil
            }

            if let data = image1Data, !viewModel.appState.isMockMode {
                do {
                    updated.image1URL = try await SupabaseService.shared.uploadImage(bucket: "items", folder: item.id, imageData: data)
                } catch {
                    isSaving = false
                    viewModel.appState.showToast("Failed to upload image", isError: true)
                    return
                }
            }

            if let data = image2Data, !viewModel.appState.isMockMode {
                do {
                    updated.image2URL = try await SupabaseService.shared.uploadImage(bucket: "items", folder: "\(item.id)/back", imageData: data)
                } catch {
                    isSaving = false
                    viewModel.appState.showToast("Failed to upload image", isError: true)
                    return
                }
            }

            do {
                if viewModel.appState.isMockMode {
                    if let index = viewModel.items.firstIndex(where: { $0.id == updated.id }) {
                        viewModel.items[index] = updated
                    }
                } else {
                    try await SupabaseService.shared.updateItem(updated)
                }
                isSaving = false
                viewModel.appState.showToast("Item updated")
                onSave()
                dismiss()
            } catch {
                isSaving = false
                viewModel.appState.showToast("Failed to update", isError: true)
            }
        }
    }
}
