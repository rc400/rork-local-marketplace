import SwiftUI

struct TCGCardSearchView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedCard: TCGCard?
    @State private var tcgService = PokemonTCGService.shared
    @State private var searchText = ""

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
            } else if tcgService.searchResults.isEmpty && searchText.count >= 2 {
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
            } else if searchText.count < 2 {
                VStack(spacing: 12) {
                    Image(systemName: "sparkle.magnifyingglass")
                        .font(.system(size: 40))
                        .foregroundStyle(.teal.opacity(0.5))
                    Text("Search for a Pokémon card")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("Type at least 2 characters to search")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 2) {
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
