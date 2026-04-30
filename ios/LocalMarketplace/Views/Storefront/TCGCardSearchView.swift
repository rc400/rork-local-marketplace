import SwiftUI

struct TCGCardSearchView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedCard: TCGCard?
    @State private var tcgService = PokemonTCGService.shared
    @State private var searchText = ""
    @State private var isApplyingTopMatch = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                searchBar
                resultsList
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Search Cards")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
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
                    if isApplyingTopMatch {
                        isApplyingTopMatch = false
                        return
                    }
                    tcgService.debouncedSearch(query: newValue)
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
        .padding(.vertical, 12)
    }

    private var resultsList: some View {
        Group {
            if tcgService.isSearching {
                VStack(spacing: 12) {
                    ProgressView()
                    Text("Searching...")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = tcgService.searchError {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundStyle(.orange)
                    Text(error)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    Button("Retry") {
                        Task { await tcgService.searchCards(query: searchText) }
                    }
                    .buttonStyle(.bordered)
                    .tint(.teal)
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if tcgService.searchResults.isEmpty && searchText.count >= 3 {
                VStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text("No results found")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("Try a different search term")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if searchText.count < 3 {
                VStack(spacing: 12) {
                    Image(systemName: "sparkle.magnifyingglass")
                        .font(.system(size: 40))
                        .foregroundStyle(.teal.opacity(0.5))
                    Text("Search for a Pokémon card")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("Type 3 characters, or press return with 2")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 2) {
                        if shouldShowTopMatches {
                            topMatchesSection
                                .padding(.bottom, 8)
                        }

                        ForEach(tcgService.searchResults) { card in
                            CardSearchRow(card: card) {
                                selectedCard = card
                                dismiss()
                            }
                        }
                    }
                }
            }
        }
    }

    private var shouldShowTopMatches: Bool {
        searchText.count >= 3 && searchText.count <= 5 && !topMatchNames.isEmpty
    }

    private var topMatchNames: [String] {
        var seenNames = Set<String>()
        var names: [String] = []

        for card in tcgService.searchResults {
            let normalizedName = card.name.lowercased()
            guard !normalizedName.isEmpty, !seenNames.contains(normalizedName) else { continue }

            seenNames.insert(normalizedName)
            names.append(card.name)

            if names.count == 5 { break }
        }

        return names
    }

    private var topMatchesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Top Matches")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 16)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(topMatchNames, id: \.self) { name in
                        Button {
                            isApplyingTopMatch = true
                            searchText = name
                            Task { await tcgService.searchCards(query: name) }
                        } label: {
                            Text(name)
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.teal)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 7)
                                .background(Color.teal.opacity(0.12))
                                .clipShape(.capsule)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
            }
        }
        .padding(.vertical, 10)
        .background(Color(.systemGroupedBackground))
    }
}

struct CardSearchRow: View {
    let card: TCGCard
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 14) {
                if let url = card.smallImageURL {
                    Color.clear
                        .aspectRatio(0.714, contentMode: .fit)
                        .frame(width: 50)
                        .overlay {
                            AsyncImage(url: url) { phase in
                                if let image = phase.image {
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                } else if phase.error != nil {
                                    cardThumbnailPlaceholder
                                } else {
                                    ProgressView()
                                }
                            }
                        }
                        .clipShape(.rect(cornerRadius: 4))
                } else {
                    cardThumbnailPlaceholder
                }

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

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color(.secondarySystemGroupedBackground))
        }
        .buttonStyle(.plain)
    }

    private var cardThumbnailPlaceholder: some View {
        Color(.tertiarySystemGroupedBackground)
            .aspectRatio(0.714, contentMode: .fit)
            .frame(width: 50)
            .overlay {
                Image(systemName: "rectangle.portrait.fill")
                    .foregroundStyle(.secondary)
            }
            .clipShape(.rect(cornerRadius: 4))
    }
}
