import SwiftUI

struct NewBinderSheet: View {
    @Environment(\.dismiss) private var dismiss
    let viewModel: StorefrontViewModel
    @State private var binderName = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Binder Name") {
                    TextField("e.g. Gen 1 Hits, Graded Cards", text: $binderName)
                }
            }
            .navigationTitle("New Binder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        createBinder()
                    }
                    .disabled(binderName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func createBinder() {
        let binder = Binder(
            id: UUID().uuidString,
            vendorID: viewModel.vendor?.userID ?? "",
            name: binderName.trimmingCharacters(in: .whitespaces),
            sortOrder: viewModel.binders.count
        )
        Task {
            await viewModel.saveBinder(binder)
            dismiss()
        }
    }
}
