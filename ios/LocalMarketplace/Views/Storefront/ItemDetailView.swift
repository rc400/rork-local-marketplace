import SwiftUI

struct ItemDetailView: View {
    let item: MarketplaceItem
    let vendorAddress: String?
    var isInCart: Bool = false
    var canAdd: Bool = true
    var onAddToCart: (() -> Void)?
    @Environment(\.dismiss) private var dismiss
    @State private var addedToCart: Bool = false

    private var isTCGItem: Bool {
        (item.category == .single || item.category == .slab) && item.tcgCardImageURL != nil
    }

    private var isSoldItem: Bool {
        item.status == .sold
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                itemImage
                    .padding(.bottom, 20)

                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(item.displayName)
                            .font(.title2.weight(.bold))

                        Text(item.formattedPrice)
                            .font(.title3.weight(.bold))
                            .foregroundStyle(.teal)
                    }

                    if let qtyLabel = item.quantityLabel, !isSoldItem {
                        HStack(spacing: 6) {
                            Image(systemName: "number.circle.fill")
                                .foregroundStyle(.teal)
                            Text(qtyLabel)
                                .font(.subheadline)
                        }
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(.rect(cornerRadius: 10))
                    }

                    if item.category == .single, let condition = item.condition {
                        detailRow(label: "Condition", value: condition.displayName)
                    }

                    if let slabLabel = item.slabDisplayLabel {
                        detailRow(label: "Grade", value: slabLabel)
                    }

                    if let note = item.note, !note.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Notes")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.secondary)
                            Text(note)
                                .font(.subheadline)
                        }
                    }

                    if isSoldItem, let soldAt = item.soldAt {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundStyle(.red)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Sold")
                                    .font(.subheadline.weight(.semibold))
                                Text(soldAt, style: .date)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.red.opacity(0.08))
                        .clipShape(.rect(cornerRadius: 12))
                    }

                    if let address = vendorAddress, !address.isEmpty {
                        HStack(spacing: 8) {
                            Image(systemName: "mappin.circle.fill")
                                .foregroundStyle(.teal)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Meetup Location")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.secondary)
                                Text(address)
                                    .font(.subheadline)
                            }
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(.rect(cornerRadius: 12))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 100)
            }
        }
        .navigationTitle(isSoldItem ? "Sold Item" : "Item Details")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            if let onAddToCart, !isSoldItem {
                Button {
                    guard canAdd else { return }
                    onAddToCart()
                    addedToCart = true
                    Task {
                        try? await Task.sleep(for: .seconds(1.5))
                        addedToCart = false
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: addedToCart ? "checkmark" : (isInCart && !canAdd ? "cart.fill" : "cart.badge.plus"))
                            .contentTransition(.symbolEffect(.replace))
                        Text(addedToCart ? "Added!" : (isInCart && !canAdd ? "In Cart (Max Qty)" : "Add to Inquiry Cart"))
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .tint(addedToCart ? .green : (isInCart && !canAdd ? .secondary : .teal))
                .disabled(!canAdd && !addedToCart)
                .clipShape(.capsule)
                .padding(.horizontal, 20)
                .padding(.bottom, 8)
                .background(.ultraThinMaterial)
            }
        }
    }

    @ViewBuilder
    private var itemImage: some View {
        if isTCGItem, let urlString = item.tcgCardImageURL, let imageURL = URL(string: urlString) {
            Color(.secondarySystemBackground)
                .aspectRatio(0.714, contentMode: .fit)
                .overlay {
                    AsyncImage(url: imageURL) { phase in
                        if let image = phase.image {
                            image.resizable().aspectRatio(contentMode: .fit)
                        } else if phase.error != nil {
                            Image(systemName: item.category.icon)
                                .font(.system(size: 48))
                                .foregroundStyle(.secondary)
                        } else {
                            ProgressView()
                        }
                    }
                    .allowsHitTesting(false)
                }
                .clipShape(.rect)
                .frame(maxHeight: 420)
        } else if let url = item.primaryImageURL, let imageURL = URL(string: url) {
            Color(.secondarySystemBackground)
                .frame(height: 300)
                .overlay {
                    AsyncImage(url: imageURL) { phase in
                        if let image = phase.image {
                            image.resizable().aspectRatio(contentMode: .fill)
                        } else {
                            Image(systemName: item.category.icon)
                                .font(.system(size: 48))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .allowsHitTesting(false)
                }
                .clipShape(.rect)
        } else {
            Color(.secondarySystemBackground)
                .frame(height: 200)
                .overlay {
                    Image(systemName: item.category.icon)
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)
                }
        }
    }

    private func detailRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.medium))
        }
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(.rect(cornerRadius: 10))
    }
}
