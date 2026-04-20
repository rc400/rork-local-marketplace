import SwiftUI

struct BinderManagementView: View {
    @Environment(\.dismiss) private var dismiss
    let viewModel: StorefrontViewModel
    @State private var showNewBinder = false
    @State private var binderToDelete: Binder?
    @State private var showDeleteOptions = false
    @State private var targetBinderForMove: String?

    private var sortedBinders: [Binder] {
        viewModel.binders.sorted { $0.sortOrder < $1.sortOrder }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(sortedBinders) { binder in
                        HStack(spacing: 12) {
                            Image(systemName: binder.isHidden ? "eye.slash.fill" : "folder.fill")
                                .foregroundStyle(binder.isHidden ? Color.secondary : Color.teal)
                                .frame(width: 28)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(binder.name)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(binder.isHidden ? .secondary : .primary)
                                Text("\(viewModel.itemsForBinder(binder.id).count) items")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Menu {
                                Button {
                                    viewModel.toggleBinderHidden(binder.id)
                                } label: {
                                    Label(
                                        binder.isHidden ? "Show" : "Hide",
                                        systemImage: binder.isHidden ? "eye" : "eye.slash"
                                    )
                                }

                                Button(role: .destructive) {
                                    binderToDelete = binder
                                    let itemCount = viewModel.itemsForBinder(binder.id).count
                                    if itemCount == 0 {
                                        viewModel.deleteBinder(binder.id, moveItemsTo: nil)
                                    } else {
                                        showDeleteOptions = true
                                    }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            } label: {
                                Image(systemName: "ellipsis")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .frame(width: 32, height: 32)
                                    .contentShape(.rect)
                            }
                        }
                    }
                    .onMove { source, destination in
                        viewModel.moveBinder(from: source, to: destination)
                    }
                } header: {
                    Text("Drag to reorder")
                } footer: {
                    Text("Hidden binders are only visible to you.")
                }
            }
            .environment(\.editMode, .constant(.active))
            .navigationTitle("Manage Binders")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showNewBinder = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showNewBinder) {
                NewBinderSheet(viewModel: viewModel)
            }
            .confirmationDialog(
                "This binder has items",
                isPresented: $showDeleteOptions,
                titleVisibility: .visible
            ) {
                let otherBinders = viewModel.binders.filter { $0.id != binderToDelete?.id }
                ForEach(otherBinders) { target in
                    Button("Move items to \(target.name)") {
                        if let binder = binderToDelete {
                            viewModel.deleteBinder(binder.id, moveItemsTo: target.id)
                        }
                        binderToDelete = nil
                    }
                }
                Button("Delete all items", role: .destructive) {
                    if let binder = binderToDelete {
                        viewModel.deleteBinder(binder.id, moveItemsTo: nil)
                    }
                    binderToDelete = nil
                }
                Button("Cancel", role: .cancel) {
                    binderToDelete = nil
                }
            } message: {
                if let binder = binderToDelete {
                    Text("'\(binder.name)' contains \(viewModel.itemsForBinder(binder.id).count) items. What would you like to do?")
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
