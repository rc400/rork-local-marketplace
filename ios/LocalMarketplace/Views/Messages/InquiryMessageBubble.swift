import SwiftUI

struct InquiryMessageBubble: View {
    let inquiry: InquiryMessageData
    let isCurrentUser: Bool
    @State private var selectedItem: InquiryItemData?

    var body: some View {
        HStack {
            if isCurrentUser { Spacer(minLength: 40) }

            VStack(alignment: isCurrentUser ? .trailing : .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "cart.fill")
                        .font(.caption)
                    Text("Card Inquiry")
                        .font(.caption.weight(.semibold))
                }
                .foregroundStyle(isCurrentUser ? .white.opacity(0.8) : .secondary)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(inquiry.items) { item in
                            InquiryCardTile(item: item)
                                .onTapGesture {
                                    selectedItem = item
                                }
                        }
                    }
                }

                if let note = inquiry.note, !note.isEmpty {
                    Text(note)
                        .font(.subheadline)
                }

                Text("Total: \(String(format: "$%.2f CAD", inquiry.total))")
                    .font(.caption.weight(.bold))
            }
            .padding(12)
            .background(isCurrentUser ? Color.teal : Color(.secondarySystemGroupedBackground))
            .foregroundStyle(isCurrentUser ? .white : .primary)
            .clipShape(.rect(cornerRadius: 18))

            if !isCurrentUser { Spacer(minLength: 40) }
        }
        .sheet(item: $selectedItem) { item in
            InquiryItemDetailSheet(item: item)
        }
    }
}

struct InquiryCardTile: View {
    let item: InquiryItemData

    var body: some View {
        VStack(spacing: 6) {
            if let urlStr = item.imageURL, let url = URL(string: urlStr) {
                AsyncImage(url: url) { phase in
                    if let image = phase.image {
                        image.resizable().aspectRatio(contentMode: .fit)
                    } else if phase.error != nil {
                        cardPlaceholder
                    } else {
                        ProgressView()
                            .frame(width: 70, height: 98)
                    }
                }
                .frame(width: 70, height: 98)
                .clipShape(.rect(cornerRadius: 6))
            } else {
                cardPlaceholder
            }

            VStack(spacing: 2) {
                Text(item.name)
                    .font(.caption2.weight(.semibold))
                    .lineLimit(2)
                    .multilineTextAlignment(.center)

                if let condition = item.condition {
                    Text(condition)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Text(item.formattedPrice)
                    .font(.caption2.weight(.bold))

                if item.quantity > 1 {
                    Text("x\(item.quantity)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(width: 90)
    }

    private var cardPlaceholder: some View {
        RoundedRectangle(cornerRadius: 6)
            .fill(Color(.tertiarySystemGroupedBackground))
            .frame(width: 70, height: 98)
            .overlay {
                Image(systemName: "rectangle.portrait.fill")
                    .foregroundStyle(.secondary)
            }
    }
}

struct InquiryItemDetailSheet: View {
    let item: InquiryItemData
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if let urlStr = item.imageURL, let url = URL(string: urlStr) {
                        AsyncImage(url: url) { phase in
                            if let image = phase.image {
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(maxWidth: 300)
                                    .clipShape(.rect(cornerRadius: 12))
                                    .shadow(radius: 8)
                            } else if phase.error != nil {
                                largePlaceholder
                            } else {
                                ProgressView()
                                    .frame(height: 400)
                            }
                        }
                    } else {
                        largePlaceholder
                    }

                    VStack(spacing: 8) {
                        Text(item.name)
                            .font(.title2.weight(.bold))

                        HStack(spacing: 16) {
                            if let condition = item.condition {
                                Label(condition, systemImage: "shield.checkered")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }

                            Text(item.formattedPrice)
                                .font(.headline)
                                .foregroundStyle(.teal)

                            if item.quantity > 1 {
                                Text("Qty: \(item.quantity)")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .padding(24)
            }
            .navigationTitle("Card Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private var largePlaceholder: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color(.tertiarySystemGroupedBackground))
            .frame(width: 250, height: 350)
            .overlay {
                Image(systemName: "rectangle.portrait.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(.secondary)
            }
    }
}
