import SwiftUI

struct MyBoardView: View {
    let viewModel: WantedBoardViewModel
    let appState: AppState
    let locationService: LocationService

    @Environment(\.dismiss) private var dismiss
    @State private var editingSlot: SlotIdentifier?

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height - 80)
            let center = CGPoint(x: geo.size.width / 2, y: (geo.size.height / 2) - 20)
            let radius = size * 0.32

            ZStack {
                ForEach(0..<5, id: \.self) { index in
                    let angle = starAngle(for: index)
                    let x = center.x + radius * cos(angle)
                    let y = center.y + radius * sin(angle)

                    slotView(index: index)
                        .position(x: x, y: y)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .navigationTitle("My Board")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Done") { dismiss() }
            }
        }
        .sheet(item: $editingSlot) { slot in
            NavigationStack {
                AddEditWantedCardView(
                    slotIndex: slot.index,
                    existingCard: viewModel.myCardForSlot(slot.index),
                    viewModel: viewModel,
                    appState: appState
                )
            }
        }
        .task {
            await viewModel.loadMyBoard()
        }
    }

    private func starAngle(for index: Int) -> CGFloat {
        let startAngle: CGFloat = -.pi / 2
        return startAngle + (CGFloat(index) * 2.0 * .pi / 5.0)
    }

    @ViewBuilder
    private func slotView(index: Int) -> some View {
        let card = viewModel.myCardForSlot(index)
        let cardWidth: CGFloat = 85
        let cardHeight: CGFloat = 118

        Button {
            editingSlot = SlotIdentifier(index: index)
        } label: {
            if let card {
                Color(.secondarySystemBackground)
                    .frame(width: cardWidth, height: cardHeight)
                    .overlay {
                        AsyncImage(url: URL(string: card.tcgCardImageURL)) { phase in
                            if let image = phase.image {
                                image.resizable().aspectRatio(contentMode: .fill)
                            } else {
                                ProgressView()
                                    .controlSize(.small)
                            }
                        }
                        .allowsHitTesting(false)
                    }
                    .clipShape(.rect(cornerRadius: 8))
                    .shadow(color: .black.opacity(0.15), radius: 6, y: 3)
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [8, 4]))
                    .foregroundStyle(.tertiary)
                    .frame(width: cardWidth, height: cardHeight)
                    .background(
                        Color(.systemGray5).opacity(0.5)
                            .clipShape(.rect(cornerRadius: 8))
                    )
                    .overlay {
                        Image(systemName: "plus")
                            .font(.title2.weight(.medium))
                            .foregroundStyle(.white)
                    }
            }
        }
        .buttonStyle(SlotButtonStyle())
    }
}

struct SlotIdentifier: Identifiable {
    let index: Int
    var id: Int { index }
}

struct SlotButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .animation(.spring(duration: 0.2), value: configuration.isPressed)
    }
}
