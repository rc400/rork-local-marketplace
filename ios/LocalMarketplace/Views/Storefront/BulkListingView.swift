import SwiftUI

struct QueuedItem: Identifiable {
    let id = UUID().uuidString
    let card: TCGCard
    var condition: ItemCondition
    var price: String
    var quantity: Int
    var binderID: String?
    var note: String = ""
    var image1Data: Data?
    var image2Data: Data?
    var hasPhotos: Bool { image1Data != nil }

    var priceValue: Double? { Double(price) }
    var isValid: Bool { (priceValue ?? 0) > 0 }
}

struct BulkListingView: View {
    @Environment(\.dismiss) private var dismiss
    let vendorID: String
    let appState: AppState

    @State private var selectedMode: BulkListingMode = .quickAdd
    @State private var queuedItems: [QueuedItem] = []
    @State private var showReview = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Listing Mode", selection: $selectedMode) {
                    ForEach(BulkListingMode.allCases) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)

                Group {
                    switch selectedMode {
                    case .quickAdd:
                        QuickAddQueueView(queuedItems: $queuedItems)
                    case .setBrowse:
                        SetBrowseView(queuedItems: $queuedItems)
                    }
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Bulk Listing")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .safeAreaInset(edge: .bottom) {
                QueueBottomBar(count: queuedItems.count) {
                    showReview = true
                }
            }
            .fullScreenCover(isPresented: $showReview) {
                ReviewQueueView(
                    queuedItems: $queuedItems,
                    vendorID: vendorID,
                    appState: appState,
                    onComplete: {}
                )
            }
        }
    }
}

private enum BulkListingMode: String, CaseIterable, Identifiable {
    case quickAdd
    case setBrowse

    var id: String { rawValue }

    var title: String {
        switch self {
        case .quickAdd: "Quick Add"
        case .setBrowse: "Set Browse"
        }
    }
}

private struct QuickAddQueueView: View {
    @Binding var queuedItems: [QueuedItem]
    @State private var tcgService = PokemonTCGService.shared
    @State private var searchText = ""
    @State private var expandedCardID: String?
    @State private var draftCondition: ItemCondition = .NM
    @State private var draftPrice = ""
    @State private var draftQuantity = 1

    var body: some View {
        VStack(spacing: 0) {
            searchBar
            resultsContent
        }
    }

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Search Pokémon cards...", text: $searchText)
                .textFieldStyle(.plain)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .onSubmit {
                    Task { await tcgService.searchCards(query: searchText) }
                }
                .onChange(of: searchText) { _, newValue in
                    tcgService.debouncedSearch(query: newValue)
                }

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                    expandedCardID = nil
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
        .padding(.bottom, 12)
    }

    private var resultsContent: some View {
        Group {
            if tcgService.isSearching {
                ProgressView("Searching...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = tcgService.searchError {
                ContentUnavailableView("Search Failed", systemImage: "exclamationmark.triangle", description: Text(error))
            } else if searchText.count < 3 {
                ContentUnavailableView(
                    "Search to Build a Queue",
                    systemImage: "bolt.fill",
                    description: Text("Add cards one at a time, then publish them together.")
                )
            } else if tcgService.searchResults.isEmpty {
                ContentUnavailableView("No Results", systemImage: "magnifyingglass", description: Text("Try a different card name or number."))
            } else {
                ScrollView {
                    LazyVStack(spacing: 2) {
                        ForEach(tcgService.searchResults) { card in
                            QuickAddCardRow(
                                card: card,
                                isExpanded: expandedCardID == card.id,
                                condition: $draftCondition,
                                price: $draftPrice,
                                quantity: $draftQuantity,
                                onTap: {
                                    withAnimation(.snappy) {
                                        if expandedCardID == card.id {
                                            expandedCardID = nil
                                        } else {
                                            expandedCardID = card.id
                                            resetDraft()
                                        }
                                    }
                                },
                                onAdd: {
                                    addToQueue(card)
                                }
                            )
                        }
                    }
                    .padding(.bottom, 12)
                }
            }
        }
    }

    private func addToQueue(_ card: TCGCard) {
        queuedItems.append(
            QueuedItem(
                card: card,
                condition: draftCondition,
                price: draftPrice,
                quantity: draftQuantity
            )
        )
        searchText = ""
        expandedCardID = nil
        resetDraft()
        tcgService.clearSearch()
    }

    private func resetDraft() {
        draftCondition = .NM
        draftPrice = ""
        draftQuantity = 1
    }
}

private struct SetBrowseView: View {
    @Binding var queuedItems: [QueuedItem]
    @State private var tcgService = PokemonTCGService.shared
    @State private var searchText = ""

    private var filteredExpansions: [ScrydexExpansionInfo] {
        let expansions = tcgService.availableExpansions.sorted {
            ($0.releaseDate ?? "") > ($1.releaseDate ?? "")
        }
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return expansions
        }
        return expansions.filter { expansion in
            expansion.name.localizedCaseInsensitiveContains(searchText)
                || (expansion.series?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }

    private var groupedExpansions: [(series: String, expansions: [ScrydexExpansionInfo])] {
        Dictionary(grouping: filteredExpansions) { $0.series ?? "Other" }
            .map { (series: $0.key, expansions: $0.value) }
            .sorted {
                let leftDate = $0.expansions.map { $0.releaseDate ?? "" }.max() ?? ""
                let rightDate = $1.expansions.map { $0.releaseDate ?? "" }.max() ?? ""
                return leftDate > rightDate
            }
    }

    var body: some View {
        List {
            ForEach(groupedExpansions, id: \.series) { group in
                Section(group.series) {
                    ForEach(group.expansions) { expansion in
                        NavigationLink {
                            SetCardGridView(expansion: expansion, queuedItems: $queuedItems)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(expansion.name)
                                    .font(.subheadline.weight(.semibold))
                                if let releaseDate = expansion.releaseDate, !releaseDate.isEmpty {
                                    Text(releaseDate)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search sets")
        .task {
            await tcgService.loadExpansions()
        }
        .overlay {
            if tcgService.availableExpansions.isEmpty {
                ProgressView("Loading sets...")
            }
        }
    }
}

private struct SetCardGridView: View {
    let expansion: ScrydexExpansionInfo
    @Binding var queuedItems: [QueuedItem]

    @State private var tcgService = PokemonTCGService.shared
    @State private var cards: [TCGCard] = []
    @State private var isLoading = true
    @State private var expandedCardID: String?
    @State private var draftCondition: ItemCondition = .NM
    @State private var draftPrice = ""
    @State private var draftQuantity = 1

    private let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]

    var body: some View {
        ScrollView {
            if isLoading {
                ProgressView("Loading cards...")
                    .frame(maxWidth: .infinity)
                    .padding(.top, 80)
            } else if cards.isEmpty {
                ContentUnavailableView("No Cards Found", systemImage: "rectangle.portrait", description: Text("This set did not return any listable cards."))
                    .padding(.top, 80)
            } else {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(cards) { card in
                        SetCardGridCell(
                            card: card,
                            isExpanded: expandedCardID == card.id,
                            condition: $draftCondition,
                            price: $draftPrice,
                            quantity: $draftQuantity,
                            onToggle: {
                                withAnimation(.snappy) {
                                    if expandedCardID == card.id {
                                        expandedCardID = nil
                                    } else {
                                        expandedCardID = card.id
                                        resetDraft()
                                    }
                                }
                            },
                            onAdd: {
                                queuedItems.append(
                                    QueuedItem(
                                        card: card,
                                        condition: draftCondition,
                                        price: draftPrice,
                                        quantity: draftQuantity
                                    )
                                )
                                expandedCardID = nil
                                resetDraft()
                            }
                        )
                    }
                }
                .padding(16)
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(expansion.name)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            isLoading = true
            cards = await tcgService.fetchSetCards(expansionId: expansion.id)
            isLoading = false
        }
    }

    private func resetDraft() {
        draftCondition = .NM
        draftPrice = ""
        draftQuantity = 1
    }
}

private struct QuickAddCardRow: View {
    let card: TCGCard
    let isExpanded: Bool
    @Binding var condition: ItemCondition
    @Binding var price: String
    @Binding var quantity: Int
    let onTap: () -> Void
    let onAdd: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Button(action: onTap) {
                HStack(spacing: 14) {
                    CardThumbnail(card: card, width: 50)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(card.displayName)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)
                        if !card.setName.isEmpty {
                            Text(card.setName)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up" : "plus.circle.fill")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.teal)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color(.secondarySystemGroupedBackground))
            }
            .buttonStyle(.plain)

            if isExpanded {
                InlineQueuedItemForm(
                    condition: $condition,
                    price: $price,
                    quantity: $quantity,
                    actionTitle: "Add to Queue",
                    onAdd: onAdd
                )
                .padding(12)
                .background(Color(.secondarySystemGroupedBackground))
            }
        }
    }
}

private struct SetCardGridCell: View {
    let card: TCGCard
    let isExpanded: Bool
    @Binding var condition: ItemCondition
    @Binding var price: String
    @Binding var quantity: Int
    let onToggle: () -> Void
    let onAdd: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            ZStack(alignment: .topTrailing) {
                CardThumbnail(card: card, width: nil)

                Button(action: onToggle) {
                    Image(systemName: isExpanded ? "xmark.circle.fill" : "plus.circle.fill")
                        .font(.title3)
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.white, .teal)
                        .padding(6)
                }
                .buttonStyle(.plain)
            }

            Text(card.number.isEmpty ? card.name : "#\(card.number)")
                .font(.caption.weight(.medium))
                .lineLimit(1)
                .frame(maxWidth: .infinity)

            if isExpanded {
                InlineQueuedItemForm(
                    condition: $condition,
                    price: $price,
                    quantity: $quantity,
                    actionTitle: "Add",
                    compact: true,
                    onAdd: onAdd
                )
            }
        }
        .padding(8)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(.rect(cornerRadius: 12))
    }
}

private struct InlineQueuedItemForm: View {
    @Binding var condition: ItemCondition
    @Binding var price: String
    @Binding var quantity: Int
    let actionTitle: String
    var compact = false
    let onAdd: () -> Void

    private var isValid: Bool {
        (Double(price) ?? 0) > 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Picker("Condition", selection: $condition) {
                ForEach(ItemCondition.allCases, id: \.self) { condition in
                    Text(condition.shortName).tag(condition)
                }
            }
            .pickerStyle(.segmented)

            if compact {
                VStack(spacing: 8) {
                    priceField
                    Stepper("Qty \(quantity)", value: $quantity, in: 1...999)
                        .font(.caption)
                }
            } else {
                HStack(spacing: 12) {
                    priceField
                    Stepper("Qty: \(quantity)", value: $quantity, in: 1...999)
                }
            }

            Button(actionTitle, action: onAdd)
                .buttonStyle(.borderedProminent)
                .tint(.teal)
                .disabled(!isValid)
                .frame(maxWidth: .infinity, alignment: compact ? .center : .trailing)
        }
    }

    private var priceField: some View {
        HStack(spacing: 4) {
            Text("$")
                .foregroundStyle(.secondary)
            TextField("Price", text: $price)
                .keyboardType(.decimalPad)
                .textFieldStyle(.plain)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 9)
        .background(Color(.tertiarySystemGroupedBackground))
        .clipShape(.rect(cornerRadius: 10))
    }
}

private struct QueueBottomBar: View {
    let count: Int
    let onReview: () -> Void

    var body: some View {
        if count > 0 {
            HStack(spacing: 12) {
                Label("\(count) \(count == 1 ? "item" : "items") in queue", systemImage: "tray.full.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)

                Spacer()

                Button("Review", action: onReview)
                    .buttonStyle(.borderedProminent)
                    .tint(.teal)
            }
            .padding(14)
            .background(.regularMaterial)
            .overlay(alignment: .top) {
                Divider()
            }
        }
    }
}

private struct CardThumbnail: View {
    let card: TCGCard
    let width: CGFloat?

    var body: some View {
        Group {
            if let url = card.smallImageURL {
                Color.clear
                    .aspectRatio(0.714, contentMode: .fit)
                    .frame(width: width)
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
                    .frame(width: width)
            }
        }
        .clipShape(.rect(cornerRadius: 6))
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
