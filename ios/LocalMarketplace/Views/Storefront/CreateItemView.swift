import SwiftUI
import PhotosUI

struct CreateItemView: View {
    @Environment(\.dismiss) private var dismiss
    let viewModel: StorefrontViewModel

    @State private var name = ""
    @State private var priceText = ""
    @State private var category: ItemCategory = .single
    @State private var condition: ItemCondition = .NM
    @State private var note = ""
    @State private var selectedBinder: String?
    @State private var status: ItemStatus = .active
    @State private var slabGrade: Int = 10
    @State private var hasSetSlabGrade = false
    @State private var slabCompany: SlabCompany?
    @State private var slabCompanyOther = ""
    @State private var quantity: Int = 1

    @State private var selectedCard: TCGCard?
    @State private var showCardSearch = false
    @State private var showNewBinderSheet = false

    @State private var image1Data: Data?
    @State private var image2Data: Data?
    @State private var isSaving = false

    private var requiresTCGSearch: Bool {
        category == .single || category == .slab
    }

    private var isValid: Bool {
        guard Double(priceText) != nil else { return false }

        switch category {
        case .single:
            return selectedCard != nil
        case .slab:
            if selectedCard == nil || !hasSetSlabGrade || slabCompany == nil { return false }
            if slabCompany == .other && slabCompanyOther.trimmingCharacters(in: .whitespaces).isEmpty { return false }
            return true
        case .accessory:
            return !name.isEmpty
        case .sealed:
            return !name.isEmpty
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                categorySection
                cardSection
                pricingSection
                binderSection
                notesSection
                photoSection
            }
            .navigationTitle("New Item")
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
            .sheet(isPresented: $showCardSearch) {
                TCGCardSearchView(selectedCard: $selectedCard)
            }
            .sheet(isPresented: $showNewBinderSheet) {
                NewBinderSheet(viewModel: viewModel)
            }
            .onChange(of: category) { _, _ in
                selectedCard = nil
                hasSetSlabGrade = false
                slabGrade = 10
                slabCompany = nil
                slabCompanyOther = ""
                image1Data = nil
                image2Data = nil
            }
        }
    }

    private var categorySection: some View {
        Section("Category") {
            Picker("Category", selection: $category) {
                ForEach(ItemCategory.allCases, id: \.self) { cat in
                    Label(cat.displayName, systemImage: cat.icon).tag(cat)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    @ViewBuilder
    private var cardSection: some View {
        if requiresTCGSearch {
            Section {
                if let card = selectedCard {
                    selectedCardPreview(card)
                } else {
                    Button {
                        showCardSearch = true
                    } label: {
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundStyle(.teal)
                            Text("Search Pokémon Card...")
                                .foregroundStyle(.secondary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
            } header: {
                Text("Card Selection")
            } footer: {
                if selectedCard == nil {
                    Text("Required — select a card from the Pokémon TCG database.")
                }
            }

            if category == .slab {
                slabDetailsSection
            }
        } else {
            Section("Item Details") {
                TextField("Item Name", text: $name)
            }
        }
    }

    private var slabDetailsSection: some View {
        Section("Slab Details") {
            VStack(alignment: .leading, spacing: 12) {
                Picker("Grading Company", selection: $slabCompany) {
                    Text("Select...").tag(nil as SlabCompany?)
                    ForEach(SlabCompany.allCases) { company in
                        Text(company.displayName).tag(company as SlabCompany?)
                    }
                }

                if slabCompany == .other {
                    TextField("Enter grading company", text: $slabCompanyOther)
                    if slabCompanyOther.trimmingCharacters(in: .whitespaces).isEmpty {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)
                                .font(.caption)
                            Text("Company name required")
                                .font(.caption)
                                .foregroundStyle(.orange)
                        }
                    }
                }
            }

            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Grade")
                    Spacer()
                    Text("\(slabGrade)")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.teal)
                }

                Picker("Grade", selection: $slabGrade) {
                    ForEach(1...10, id: \.self) { grade in
                        Text("\(grade)").tag(grade)
                    }
                }
                .pickerStyle(.segmented)
                .onChange(of: slabGrade) { _, _ in
                    hasSetSlabGrade = true
                }
            }

            if !hasSetSlabGrade {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                        .font(.caption)
                    Text("Please confirm the slab grade")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }
        }
    }

    private func selectedCardPreview(_ card: TCGCard) -> some View {
        VStack(spacing: 12) {
            if let url = card.largeImageURL ?? card.smallImageURL {
                Color.clear
                    .aspectRatio(0.714, contentMode: .fit)
                    .frame(maxWidth: 180)
                    .overlay {
                        AsyncImage(url: url) { phase in
                            if let image = phase.image {
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                            } else if phase.error != nil {
                                cardPlaceholder
                            } else {
                                ProgressView()
                            }
                        }
                    }
                    .clipShape(.rect(cornerRadius: 8))
            }

            VStack(spacing: 4) {
                Text(card.displayName)
                    .font(.headline)
                if !card.setName.isEmpty {
                    Text(card.setName)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Button {
                showCardSearch = true
            } label: {
                Text("Change Card")
                    .font(.subheadline.weight(.medium))
            }
            .buttonStyle(.bordered)
            .tint(.teal)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    private var cardPlaceholder: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color(.tertiarySystemGroupedBackground))
            .aspectRatio(63.0/88.0, contentMode: .fit)
            .frame(maxWidth: 180)
            .overlay {
                Image(systemName: "rectangle.portrait.fill")
                    .font(.largeTitle)
                    .foregroundStyle(.secondary)
            }
    }

    private var pricingSection: some View {
        Section {
            TextField("Price (CAD)", text: $priceText)
                .keyboardType(.decimalPad)

            Stepper("Quantity: \(quantity)", value: $quantity, in: 1...999)

            if category.hasCondition {
                Picker("Condition", selection: $condition) {
                    ForEach(ItemCondition.allCases, id: \.self) { cond in
                        Text(cond.displayName).tag(cond)
                    }
                }
            }
        } header: {
            Text(category.hasCondition ? "Pricing & Condition" : "Pricing")
        }
    }

    private var binderSection: some View {
        Section("Binder") {
            Picker("Binder", selection: $selectedBinder) {
                Text("None").tag(nil as String?)
                ForEach(viewModel.binders) { binder in
                    Text(binder.name).tag(binder.id as String?)
                }
            }

            Button {
                showNewBinderSheet = true
            } label: {
                Label("Create New Binder", systemImage: "plus.circle.fill")
                    .foregroundStyle(.teal)
            }
        }
    }

    private var notesSection: some View {
        Section {
            TextField("Note (optional)", text: $note, axis: .vertical)
                .lineLimit(2...4)
        }
    }

    @ViewBuilder
    private var photoSection: some View {
        if category == .single, condition.requiresImages {
            Section {
                HStack(spacing: 8) {
                    Image(systemName: "camera.fill")
                        .foregroundStyle(.orange)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("2 damage photos required")
                            .font(.subheadline.weight(.medium))
                        Text("Add 2 photos showing card condition.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                ImagePickerButton(label: "Front Photo", currentURL: nil, imageData: $image1Data)
                ImagePickerButton(label: "Back Photo", currentURL: nil, imageData: $image2Data)
            } header: {
                Text("Damage Photos")
            }
        } else if category == .accessory {
            Section {
                ImagePickerButton(label: "Choose Photo", currentURL: nil, imageData: $image1Data)
            } header: {
                Text("Item Photo")
            } footer: {
                Text("At least 1 photo required for accessories.")
            }
        }
    }

    private func saveItem() {
        guard let price = Double(priceText) else { return }
        isSaving = true

        let itemName: String
        if requiresTCGSearch, let card = selectedCard {
            itemName = card.displayName
        } else {
            itemName = name
        }

        let itemCondition: ItemCondition? = category.hasCondition ? condition : nil
        let companyValue: String? = category == .slab ? slabCompany?.rawValue : nil
        let itemID = UUID().uuidString

        Task {
            defer { isSaving = false }
            var img1URL: String?
            var img2URL: String?

            if let data = image1Data, !viewModel.appState.isMockMode {
                do {
                    img1URL = try await SupabaseService.shared.uploadImage(bucket: "items", folder: itemID, imageData: data)
                } catch {
                    viewModel.appState.showToast("Failed to upload image", isError: true)
                    return
                }
            }
            if let data = image2Data, !viewModel.appState.isMockMode {
                do {
                    img2URL = try await SupabaseService.shared.uploadImage(bucket: "items", folder: "\(itemID)/back", imageData: data)
                } catch {
                    viewModel.appState.showToast("Failed to upload image", isError: true)
                    return
                }
            }

            let item = MarketplaceItem(
                id: itemID,
                vendorID: viewModel.vendor?.userID ?? "",
                binderID: selectedBinder,
                name: itemName,
                priceCAD: price,
                category: category,
                condition: itemCondition,
                note: note.isEmpty ? nil : note,
                status: status,
                image1URL: img1URL,
                image2URL: img2URL,
                tcgCardID: selectedCard?.id,
                tcgCardName: selectedCard?.name,
                tcgCardNumber: selectedCard?.number,
                tcgCardDisplay: selectedCard?.displayName,
                tcgCardImageURL: selectedCard?.imageLarge,
                slabGrade: category == .slab ? slabGrade : nil,
                slabCompany: companyValue,
                slabCompanyOther: category == .slab && slabCompany == .other ? slabCompanyOther.trimmingCharacters(in: .whitespaces) : nil,
                quantity: quantity
            )
            if await viewModel.saveItem(item) {
                dismiss()
            }
        }
    }
}
