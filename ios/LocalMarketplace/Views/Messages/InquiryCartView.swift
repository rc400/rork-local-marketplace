import SwiftUI

struct InquiryCartView: View {
    @Environment(\.dismiss) private var dismiss
    let viewModel: StorefrontViewModel
    let appState: AppState

    @State private var messagesVM: MessagesViewModel
    @State private var customNote: String = ""

    private let defaultNote = "Hi! I’m interested in these items. Are they still available?"

    init(viewModel: StorefrontViewModel, appState: AppState) {
        self.viewModel = viewModel
        self.appState = appState
        _messagesVM = State(initialValue: MessagesViewModel(appState: appState))
    }

    private var cartSnapshot: [InquiryCartItem] {
        viewModel.inquiryCart
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(cartSnapshot) { cartItem in
                            cartRow(cartItem)
                            if cartItem.id != cartSnapshot.last?.id {
                                Divider()
                                    .padding(.leading, 16)
                            }
                        }
                    }
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(.rect(cornerRadius: 12))
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                }

                VStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 8) {
                        TextField("Add a message (optional)...", text: $customNote, prompt: Text(defaultNote), axis: .vertical)
                            .lineLimit(2...4)
                            .padding(12)
                            .background(Color(.secondarySystemGroupedBackground))
                            .clipShape(.rect(cornerRadius: 12))

                        Button("Use default message") {
                            customNote = defaultNote
                        }
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.teal)
                    }

                    HStack {
                        Text("Total")
                            .font(.subheadline.weight(.semibold))
                        Spacer()
                        Text(formattedTotal)
                            .font(.subheadline.weight(.bold))
                    }

                    Button {
                        Task {
                            let messageBody = makeInquiryMessageBody()
                            let didSend = await messagesVM.sendInquiry(
                                otherUserID: viewModel.vendor?.userID ?? "",
                                cartMessage: messageBody
                            )
                            if didSend {
                                viewModel.clearCart()
                                dismiss()
                            }
                        }
                    } label: {
                        Text("Send Inquiry")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.teal)
                    .clipShape(.capsule)
                }
                .padding(16)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Inquiry Cart")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Clear") {
                        viewModel.clearCart()
                        scheduleDismiss()
                    }
                    .foregroundStyle(.red)
                }
            }
        }
    }

    private func cartRow(_ cartItem: InquiryCartItem) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(cartItem.item.displayName)
                    .font(.subheadline.weight(.medium))
                Text(cartItem.item.condition != nil ? "\(cartItem.item.formattedPrice) \u{2022} \(cartItem.item.condition!.shortName)" : cartItem.item.formattedPrice)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if cartItem.item.quantity > 1 {
                HStack(spacing: 8) {
                    Button {
                        viewModel.decrementCart(cartItem.item.id)
                        checkEmpty()
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)

                    Text("\(cartItem.quantity)")
                        .font(.subheadline.weight(.semibold))
                        .monospacedDigit()
                        .frame(minWidth: 20)

                    Button {
                        viewModel.incrementCart(cartItem.item.id)
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(cartItem.quantity >= cartItem.item.quantity ? Color.secondary.opacity(0.4) : Color.teal)
                    }
                    .buttonStyle(.plain)
                    .disabled(cartItem.quantity >= cartItem.item.quantity)
                }
            } else if cartItem.quantity > 1 {
                Text("x\(cartItem.quantity)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            Button(role: .destructive) {
                withAnimation {
                    viewModel.removeFromCart(cartItem.item.id)
                }
                checkEmpty()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var formattedTotal: String {
        String(format: "$%.2f CAD", cartTotal)
    }

    private var cartTotal: Double {
        viewModel.inquiryCart.reduce(0.0) { $0 + $1.item.priceCAD * Double($1.quantity) }
    }

    private func makeInquiryMessageBody() -> String {
        let inquiryItems = viewModel.inquiryCart.map { cartItem in
            InquiryItemData(
                itemID: cartItem.item.id,
                name: cartItem.item.displayName,
                price: cartItem.item.priceCAD,
                condition: cartItem.item.condition?.shortName,
                quantity: cartItem.quantity,
                imageURL: cartItem.item.primaryImageURL
            )
        }
        let trimmedNote = customNote.trimmingCharacters(in: .whitespacesAndNewlines)
        let inquiry = InquiryMessageData(
            items: inquiryItems,
            note: trimmedNote.isEmpty ? nil : trimmedNote,
            total: cartTotal
        )
        let encoder = JSONEncoder()
        let jsonData = try! encoder.encode(inquiry)
        let jsonString = String(data: jsonData, encoding: .utf8)!
        return "\(Message.inquiryPrefix)\(jsonString)"
    }

    private func checkEmpty() {
        if viewModel.inquiryCart.isEmpty {
            scheduleDismiss()
        }
    }

    private func scheduleDismiss() {
        Task {
            try? await Task.sleep(for: .seconds(0.35))
            dismiss()
        }
    }
}
