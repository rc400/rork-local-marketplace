import SwiftUI

struct EditBinderSheet: View {
    @Environment(\.dismiss) private var dismiss
    let viewModel: StorefrontViewModel
    let binder: Binder
    @State private var binderName: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Binder Name") {
                    TextField("e.g. Gen 1 Hits, Graded Cards", text: $binderName)
                }
            }
            .navigationTitle("Rename Binder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        renameBinder()
                    }
                    .disabled(binderName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                binderName = binder.name
            }
        }
        .presentationDetents([.medium])
    }

    private func renameBinder() {
        let newName = binderName.trimmingCharacters(in: .whitespaces)
        guard !newName.isEmpty else { return }
        Task {
            await viewModel.renameBinder(binderID: binder.id, newName: newName)
            dismiss()
        }
    }
}
