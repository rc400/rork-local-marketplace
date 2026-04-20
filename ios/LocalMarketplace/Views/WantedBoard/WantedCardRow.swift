import SwiftUI

struct WantedCardRow: View {
    let card: WantedCard
    let distanceString: String

    var body: some View {
        HStack(spacing: 12) {
            Color(.secondarySystemBackground)
                .frame(width: 72, height: 100)
                .overlay {
                    AsyncImage(url: URL(string: card.tcgCardImageURL)) { phase in
                        if let image = phase.image {
                            image.resizable().aspectRatio(contentMode: .fill)
                        } else if phase.error != nil {
                            Image(systemName: "rectangle.portrait.slash")
                                .foregroundStyle(.tertiary)
                        } else {
                            ProgressView()
                                .controlSize(.small)
                        }
                    }
                    .allowsHitTesting(false)
                }
                .clipShape(.rect(cornerRadius: 6))

            VStack(alignment: .leading, spacing: 4) {
                Text(card.tcgCardName)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)

                Text("Offer $\(card.bidPrice, specifier: "%.2f")")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.teal)

                Text(card.conditionsDisplay)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                if card.isGraded, let company = card.gradingCompany {
                    Text("\(company) · \(card.gradesDisplay)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                HStack(spacing: 4) {
                    Image(systemName: "location.fill")
                        .font(.caption2)
                    Text(distanceString)
                        .font(.caption)
                }
                .foregroundStyle(.tertiary)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}
