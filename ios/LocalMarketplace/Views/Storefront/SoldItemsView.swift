import SwiftUI

struct SoldItemsView: View {
    @Environment(\.dismiss) private var dismiss
    let viewModel: StorefrontViewModel
    @State private var selectedSoldItem: MarketplaceItem?

    var body: some View {
        Group {
            if viewModel.soldItems.isEmpty {
                ContentUnavailableView("No Sold Items", systemImage: "checkmark.circle", description: Text("Items you mark as sold will appear here."))
            } else {
                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                        ForEach(viewModel.soldItems) { item in
                            Button {
                                selectedSoldItem = item
                            } label: {
                                soldCard(item)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 24)
                }
            }
        }
        .navigationTitle("Sold Items")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Done") { dismiss() }
            }
        }
        .navigationDestination(item: $selectedSoldItem) { item in
            ItemDetailView(
                item: item,
                vendorAddress: viewModel.vendor?.meetupAddress
            )
        }
    }

    private func soldCard(_ item: MarketplaceItem) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            if let urlString = item.primaryImageURL, let imageURL = URL(string: urlString) {
                Color(.tertiarySystemGroupedBackground)
                    .aspectRatio(0.714, contentMode: .fit)
                    .overlay {
                        AsyncImage(url: imageURL) { phase in
                            if let image = phase.image {
                                image.resizable().aspectRatio(contentMode: .fit)
                            } else {
                                Image(systemName: "checkmark.circle")
                                    .font(.largeTitle)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .allowsHitTesting(false)
                    }
                    .clipShape(.rect(cornerRadius: 8))
                    .overlay(alignment: .topTrailing) {
                        Text("SOLD")
                            .font(.caption2.weight(.black))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(.red)
                            .foregroundStyle(.white)
                            .clipShape(.capsule)
                            .padding(6)
                    }
            } else {
                Color(.tertiarySystemGroupedBackground)
                    .frame(height: 100)
                    .overlay {
                        Image(systemName: item.category.icon)
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                    }
                    .clipShape(.rect(cornerRadius: 8))
            }

            Text(item.displayName)
                .font(.subheadline.weight(.semibold))
                .lineLimit(1)

            Text(item.formattedPrice)
                .font(.caption.weight(.bold))
                .foregroundStyle(.teal)

            if let soldAt = item.soldAt {
                Text(soldAt, style: .date)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(10)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(.rect(cornerRadius: 14))
        .opacity(0.85)
    }
}
