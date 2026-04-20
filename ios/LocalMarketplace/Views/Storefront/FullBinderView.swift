import SwiftUI

struct FullBinderView: View {
    let binder: Binder
    let viewModel: StorefrontViewModel
    let appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var showMoveSheet = false
    @State private var showHideConfirm = false
    @State private var showSoldConfirm = false
    @State private var showDeleteConfirm = false
    @State private var selectedItemForDetail: MarketplaceItem?
    @State private var quickAddedItemID: String?

    private var binderItems: [MarketplaceItem] {
        viewModel.itemsForBinder(binder.id)
    }

    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                ForEach(binderItems) { item in
                    ItemCard(
                        item: item,
                        isOwnStore: viewModel.isOwnStore,
                        isSelected: viewModel.selectedItemIDs.contains(item.id),
                        onTap: {
                            if viewModel.isBulkMode {
                                viewModel.toggleSelection(item.id)
                            } else {
                                selectedItemForDetail = item
                            }
                        },
                        onQuickAdd: {
                            viewModel.addToCart(item)
                            quickAddedItemID = item.id
                            Task {
                                try? await Task.sleep(for: .seconds(1.2))
                                if quickAddedItemID == item.id {
                                    quickAddedItemID = nil
                                }
                            }
                        },
                        onSelect: viewModel.isBulkMode ? {
                            viewModel.toggleSelection(item.id)
                        } : nil,
                        isQuickAdded: quickAddedItemID == item.id,
                        isInCart: viewModel.cartQuantity(for: item.id) > 0,
                        canAdd: viewModel.canAddToCart(item)
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 24)

            if binderItems.isEmpty {
                ContentUnavailableView("No Cards", systemImage: "tray", description: Text("This binder is empty."))
                    .padding(.top, 40)
            }

            if !binderItems.isEmpty {
                Text("No more cards.")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .padding(.bottom, 32)
            }
        }
        .navigationTitle(binder.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Close") { dismiss() }
            }

            if viewModel.isOwnStore {
                ToolbarItem(placement: .topBarTrailing) {
                    if viewModel.isBulkMode {
                        Button("Done") {
                            viewModel.exitBulkMode()
                        }
                    } else {
                        Button {
                            viewModel.isBulkMode = true
                        } label: {
                            Image(systemName: "checklist")
                        }
                    }
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            if viewModel.isBulkMode && !viewModel.selectedItemIDs.isEmpty {
                bulkActionBar
            } else if !viewModel.isOwnStore && !viewModel.inquiryCart.isEmpty {
                inquiryBar
            }
        }
        .navigationDestination(item: $selectedItemForDetail) { item in
            ItemDetailView(
                item: item,
                vendorAddress: viewModel.vendor?.meetupAddress,
                isInCart: viewModel.cartQuantity(for: item.id) > 0,
                canAdd: viewModel.canAddToCart(item),
                onAddToCart: viewModel.isOwnStore ? nil : {
                    viewModel.addToCart(item)
                }
            )
        }
        .sheet(isPresented: $showMoveSheet) {
            moveToBinderSheet
        }
        .alert("Hide \(viewModel.selectedItemIDs.count) Item(s)?", isPresented: $showHideConfirm) {
            Button(viewModel.bulkHideLabel, role: .destructive) {
                viewModel.bulkToggleHide()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            let label = viewModel.bulkHideLabel.lowercased()
            Text("This will \(label) \(viewModel.selectedItemIDs.count) selected item(s).")
        }
        .alert("Mark \(viewModel.selectedItemIDs.count) Item(s) as Sold?", isPresented: $showSoldConfirm) {
            Button("Mark Sold", role: .destructive) {
                viewModel.bulkMarkSold()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("\(viewModel.selectedItemIDs.count) item(s) will be moved to the Sold section.")
        }
        .alert("Delete \(viewModel.selectedItemIDs.count) Item(s)?", isPresented: $showDeleteConfirm) {
            Button("Delete", role: .destructive) {
                viewModel.bulkDelete()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete \(viewModel.selectedItemIDs.count) selected item(s). This cannot be undone.")
        }
    }

    private var bulkActionBar: some View {
        VStack(spacing: 0) {
            Divider()
            VStack(spacing: 10) {
                Text("\(viewModel.selectedItemIDs.count) selected")
                    .font(.subheadline.weight(.semibold))

                HStack(spacing: 8) {
                    Button {
                        showHideConfirm = true
                    } label: {
                        Label(viewModel.bulkHideLabel, systemImage: viewModel.bulkHideIcon)
                            .font(.caption.weight(.semibold))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .tint(.orange)
                    .clipShape(.capsule)

                    Button {
                        showMoveSheet = true
                    } label: {
                        Label("Move", systemImage: "folder")
                            .font(.caption.weight(.semibold))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .tint(.blue)
                    .clipShape(.capsule)

                    Button {
                        showSoldConfirm = true
                    } label: {
                        Label("Sold", systemImage: "checkmark.circle")
                            .font(.caption.weight(.semibold))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .tint(.green)
                    .clipShape(.capsule)

                    Button {
                        showDeleteConfirm = true
                    } label: {
                        Label("Delete", systemImage: "trash")
                            .font(.caption.weight(.semibold))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                    .clipShape(.capsule)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(.ultraThinMaterial)
        }
    }

    private var inquiryBar: some View {
        Button {
            viewModel.showInquiryCart = true
        } label: {
            HStack {
                Image(systemName: "cart.fill")
                Text("\(viewModel.inquiryCart.count) item\(viewModel.inquiryCart.count == 1 ? "" : "s")")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text("Send Inquiry")
                    .font(.subheadline.weight(.bold))
            }
            .padding(16)
            .background(.teal, in: .capsule)
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
        }
    }

    private var moveToBinderSheet: some View {
        NavigationStack {
            List {
                ForEach(viewModel.binders.filter { $0.id != binder.id }) { targetBinder in
                    Button {
                        viewModel.bulkMoveToBinder(targetBinder.id)
                        showMoveSheet = false
                    } label: {
                        HStack {
                            Image(systemName: "folder.fill")
                                .foregroundStyle(.teal)
                            Text(targetBinder.name)
                            Spacer()
                            Text("\(viewModel.itemsForBinder(targetBinder.id).count) items")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Move To…")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showMoveSheet = false }
                }
            }
        }
        .presentationDetents([.medium])
    }
}
