import SwiftUI

struct CategoryBadge: View {
    let text: String
    var style: BadgeStyle = .standard

    enum BadgeStyle {
        case standard, active, inactive
    }

    var body: some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(backgroundColor.opacity(0.15))
            .foregroundStyle(backgroundColor)
            .clipShape(.capsule)
    }

    private var backgroundColor: Color {
        switch style {
        case .standard: .blue
        case .active: .green
        case .inactive: .secondary
        }
    }
}

struct VerifiedBadge: View {
    var body: some View {
        Image(systemName: "checkmark.seal.fill")
            .font(.caption)
            .foregroundStyle(.blue)
    }
}
