import SwiftUI

struct SlabFrameView: View {
    let cardImageURL: String?
    let company: String
    let companyOther: String?
    let grade: Int
    var width: CGFloat = 160

    private var height: CGFloat { width * 1.5 }
    private var labelHeight: CGFloat { height * 0.25 }
    private var companyValue: SlabCompany {
        SlabCompany(rawValue: company) ?? .other
    }
    private var brandColor: Color { companyValue.brandColor }
    private var companyLabel: String {
        if companyValue == .other,
           let companyOther,
           !companyOther.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return companyOther.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return companyValue.shortName
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(
                    LinearGradient(
                        colors: [Color(.systemGray3), Color(.systemGray4)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            VStack(spacing: 0) {
                gradingLabel
                    .frame(height: labelHeight)

                cardImageSection
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .clipShape(.rect(cornerRadius: 6))
            .padding(4)
        }
        .frame(width: width, height: height)
        .shadow(color: .black.opacity(0.2), radius: 6, y: 3)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(companyLabel) graded card, grade \(grade)")
    }

    private var gradingLabel: some View {
        VStack(spacing: 0) {
            brandColor
                .frame(height: 2)

            HStack(alignment: .center, spacing: 8) {
                Text(companyLabel)
                    .font(.system(size: max(13, width * 0.12), weight: .black, design: .rounded))
                    .foregroundStyle(brandColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.55)

                Spacer(minLength: 4)

                Text("\(grade)")
                    .font(.system(size: max(26, width * 0.28), weight: .black, design: .rounded))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .padding(.horizontal, max(8, width * 0.08))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                LinearGradient(
                    colors: [Color(.systemBackground), Color(.secondarySystemBackground)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
    }

    private var cardImageSection: some View {
        Color(white: 0.12)
            .overlay {
                Group {
                    if let cardImageURL, let url = URL(string: cardImageURL) {
                        AsyncImage(url: url) { phase in
                            if let image = phase.image {
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                            } else if phase.error != nil {
                                placeholderImage
                            } else {
                                ProgressView()
                                    .tint(.white)
                            }
                        }
                        .allowsHitTesting(false)
                    } else {
                        placeholderImage
                    }
                }
                .padding(width * 0.08)
            }
    }

    private var placeholderImage: some View {
        Image(systemName: "rectangle.portrait.fill")
            .font(.system(size: max(28, width * 0.28)))
            .foregroundStyle(.white.opacity(0.45))
    }
}

#Preview {
    VStack(spacing: 24) {
        SlabFrameView(
            cardImageURL: nil,
            company: SlabCompany.PSA.rawValue,
            companyOther: nil,
            grade: 10
        )

        SlabFrameView(
            cardImageURL: nil,
            company: SlabCompany.BGS.rawValue,
            companyOther: nil,
            grade: 9,
            width: 220
        )
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
