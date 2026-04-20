import SwiftUI

struct AddEditWantedCardView: View {
    let slotIndex: Int
    let existingCard: WantedCard?
    let viewModel: WantedBoardViewModel
    let appState: AppState

    @Environment(\.dismiss) private var dismiss
    private var tcgService: PokemonTCGService { PokemonTCGService.shared }
    @State private var selectedTCGCard: TCGCard?
    @State private var cardSearchText: String = ""
    @State private var bidPriceText: String = ""
    @State private var selectedConditions: Set<CardConditionOption> = []
    @State private var selectedGradingCompany: SlabCompany = .PSA
    @State private var selectedGrades: Set<GradeValue> = []
    @State private var notes: String = ""
    @State private var showDeleteAlert: Bool = false
    @State private var isSaving: Bool = false
    @State private var showCardPicker: Bool = false

    private var isEditing: Bool { existingCard != nil }

    private var canSave: Bool {
        selectedTCGCard != nil &&
        !bidPriceText.isEmpty &&
        (Double(bidPriceText) ?? 0) > 0 &&
        !selectedConditions.isEmpty &&
        (!selectedConditions.contains(.Graded) || !selectedGrades.isEmpty)
    }

    var body: some View {
        Form {
            cardSection
            pricingSection
            conditionSection

            if selectedConditions.contains(.Graded) {
                gradingSection
            }

            notesSection
        }
        .navigationTitle(isEditing ? "Edit Listing" : "Add Listing")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") { save() }
                    .disabled(!canSave || isSaving)
            }
            if isEditing {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showDeleteAlert = true } label: {
                        Image(systemName: "trash")
                            .foregroundStyle(.red)
                    }
                }
            }
        }
        .alert("Delete Listing?", isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive) {
                Task {
                    if let id = existingCard?.id {
                        await viewModel.deleteWantedCard(id: id)
                        dismiss()
                    }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently remove this wanted card listing.")
        }
        .onAppear { populateExisting() }
    }

    private var cardSection: some View {
        Section {
            if let card = selectedTCGCard {
                HStack(spacing: 12) {
                    Color(.secondarySystemBackground)
                        .frame(width: 60, height: 84)
                        .overlay {
                            AsyncImage(url: card.smallImageURL) { phase in
                                if let image = phase.image {
                                    image.resizable().aspectRatio(contentMode: .fill)
                                }
                            }
                            .allowsHitTesting(false)
                        }
                        .clipShape(.rect(cornerRadius: 6))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(card.name)
                            .font(.subheadline.weight(.semibold))
                        Text("\(card.setName) · #\(card.number)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Button("Change") { showCardPicker = true }
                        .font(.subheadline)
                }
            } else {
                Button {
                    showCardPicker = true
                } label: {
                    HStack {
                        Image(systemName: "magnifyingglass")
                        Text("Search for a card")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
        } header: {
            Text("Card")
        }
        .sheet(isPresented: $showCardPicker) {
            CardSearchPickerView(tcgService: tcgService, selectedCard: $selectedTCGCard)
        }
    }

    private var pricingSection: some View {
        Section("Bid Price") {
            HStack {
                Text("$")
                    .foregroundStyle(.secondary)
                TextField("0.00", text: $bidPriceText)
                    .keyboardType(.decimalPad)
                Text("CAD")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
    }

    private var conditionSection: some View {
        Section("Condition") {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 80), spacing: 8)], alignment: .leading, spacing: 8) {
                ForEach(CardConditionOption.allCases) { condition in
                    Button {
                        toggleCondition(condition)
                    } label: {
                        Text(condition.shortName)
                            .font(.caption.weight(.medium))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity)
                            .background(selectedConditions.contains(condition) ? Color.teal : Color(.secondarySystemGroupedBackground))
                            .foregroundStyle(selectedConditions.contains(condition) ? .white : .primary)
                            .clipShape(.rect(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var gradingSection: some View {
        Section {
            Picker("Grading Company", selection: $selectedGradingCompany) {
                ForEach(SlabCompany.allCases) { company in
                    Text(company.displayName).tag(company)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Acceptable Grades")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 50), spacing: 6)], alignment: .leading, spacing: 6) {
                    ForEach(GradeValue.allCases) { grade in
                        Button {
                            if selectedGrades.contains(grade) {
                                selectedGrades.remove(grade)
                            } else {
                                selectedGrades.insert(grade)
                            }
                        } label: {
                            Text(grade.displayName)
                                .font(.caption.weight(.medium))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(selectedGrades.contains(grade) ? Color.teal : Color(.secondarySystemGroupedBackground))
                                .foregroundStyle(selectedGrades.contains(grade) ? .white : .primary)
                                .clipShape(.rect(cornerRadius: 6))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        } header: {
            Text("Grading Details")
        }
    }

    private var notesSection: some View {
        Section {
            TextField("Any additional details...", text: $notes, axis: .vertical)
                .lineLimit(3...5)
            HStack {
                Spacer()
                Text("\(notes.count)/250")
                    .font(.caption2)
                    .foregroundStyle(notes.count > 250 ? Color.red : Color.gray)
            }
        } header: {
            Text("Notes (Optional)")
        }
    }

    private func toggleCondition(_ condition: CardConditionOption) {
        if condition == .Graded {
            if selectedConditions.contains(.Graded) {
                selectedConditions.remove(.Graded)
            } else {
                selectedConditions = [.Graded]
            }
        } else {
            selectedConditions.remove(.Graded)
            if selectedConditions.contains(condition) {
                selectedConditions.remove(condition)
            } else {
                selectedConditions.insert(condition)
            }
        }
    }

    private func populateExisting() {
        guard let card = existingCard else { return }
        selectedTCGCard = TCGCard(
            id: card.tcgCardID,
            name: card.tcgCardName,
            number: card.tcgCardNumber,
            setName: card.tcgCardSetName,
            setId: "",
            releaseDate: "",
            subtypes: [],
            rarity: "",
            imageSmall: card.tcgCardImageURL,
            imageLarge: card.tcgCardImageURL
        )
        bidPriceText = String(format: "%.2f", card.bidPrice)
        selectedConditions = Set(card.conditions.compactMap { CardConditionOption(rawValue: $0) })
        if let company = card.gradingCompany {
            selectedGradingCompany = SlabCompany(rawValue: company) ?? .PSA
        }
        if let grades = card.grades {
            selectedGrades = Set(grades.compactMap { GradeValue(rawValue: $0) })
        }
        notes = card.notes ?? ""
    }

    private func save() {
        guard let tcgCard = selectedTCGCard, let price = Double(bidPriceText), notes.count <= 250 else { return }
        isSaving = true

        Task {
            let success = await viewModel.saveWantedCard(
                existingID: existingCard?.id,
                slotIndex: slotIndex,
                card: tcgCard,
                bidPrice: price,
                conditions: selectedConditions,
                gradingCompany: selectedConditions.contains(.Graded) ? selectedGradingCompany : nil,
                grades: selectedGrades,
                notes: notes.isEmpty ? nil : notes
            )
            isSaving = false
            if success { dismiss() }
        }
    }
}

struct CardSearchPickerView: View {
    let tcgService: PokemonTCGService
    @Binding var selectedCard: TCGCard?
    @Environment(\.dismiss) private var dismiss
    @State private var searchText: String = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField("Search cards...", text: $searchText)
                        .autocorrectionDisabled()
                        .onSubmit {
                            tcgService.debouncedSearch(query: searchText)
                        }

                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                            tcgService.clearSearch()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(12)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(.rect(cornerRadius: 12))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)

                if tcgService.isSearching {
                    Spacer()
                    ProgressView("Searching...")
                    Spacer()
                } else if let error = tcgService.searchError {
                    Spacer()
                    Text(error)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                } else if tcgService.searchResults.isEmpty && !searchText.isEmpty {
                    Spacer()
                    Text("No results found")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                } else {
                    List(tcgService.searchResults) { card in
                        Button {
                            selectedCard = card
                            dismiss()
                        } label: {
                            HStack(spacing: 12) {
                                Color(.secondarySystemBackground)
                                    .frame(width: 50, height: 70)
                                    .overlay {
                                        AsyncImage(url: card.smallImageURL) { phase in
                                            if let image = phase.image {
                                                image.resizable().aspectRatio(contentMode: .fill)
                                            }
                                        }
                                        .allowsHitTesting(false)
                                    }
                                    .clipShape(.rect(cornerRadius: 4))

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(card.name)
                                        .font(.subheadline.weight(.medium))
                                        .foregroundStyle(.primary)
                                    Text("\(card.setName) · #\(card.number)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    if !card.rarity.isEmpty {
                                        Text(card.rarity)
                                            .font(.caption2)
                                            .foregroundStyle(.tertiary)
                                    }
                                }
                                Spacer()
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Find Card")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onChange(of: searchText) { _, newValue in
                tcgService.debouncedSearch(query: newValue)
            }
        }
    }
}
