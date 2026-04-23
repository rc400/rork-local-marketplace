import Foundation
import SwiftUI

@Observable
@MainActor
class StorefrontViewModel {
    var vendor: Vendor?
    var binders: [Binder] = []
    var items: [MarketplaceItem] = []
    var isLoading: Bool = false
    var inquiryCart: [InquiryCartItem] = []
    var showInquiryCart: Bool = false
    var selectedItemIDs: Set<String> = []
    var isBulkMode: Bool = false

    let appState: AppState

    init(appState: AppState) {
        self.appState = appState
    }

    func loadStorefront(vendorID: String) async {
        isLoading = true
        defer { isLoading = false }

        if appState.isMockMode {
            if let currentVendor = appState.currentVendor, currentVendor.userID == vendorID {
                vendor = currentVendor
            } else {
                vendor = MockDataService.shared.vendor(for: vendorID)
            }
            binders = MockDataService.shared.vendorBinders(vendorID: vendorID)
            items = MockDataService.shared.vendorItems(vendorID: vendorID)
        } else {
            do {
                if let currentVendor = appState.currentVendor, currentVendor.userID == vendorID {
                    vendor = currentVendor
                } else {
                    vendor = try await SupabaseService.shared.fetchVendor(userID: vendorID)
                }
                binders = try await SupabaseService.shared.fetchBinders(vendorID: vendorID)
                items = try await SupabaseService.shared.fetchItems(vendorID: vendorID)
            } catch {
                appState.showToast("Failed to load storefront", isError: true)
            }
        }
    }

    func refreshVendorFromAppState() {
        if let currentVendor = appState.currentVendor, currentVendor.userID == vendor?.userID {
            vendor = currentVendor
        }
    }

    var visibleBinders: [Binder] {
        if isOwnStore {
            return binders.sorted { $0.sortOrder < $1.sortOrder }
        }
        return binders.filter { !$0.isHidden }.sorted { $0.sortOrder < $1.sortOrder }
    }

    var activeItems: [MarketplaceItem] {
        items.filter { $0.status != .sold }
    }

    var soldItems: [MarketplaceItem] {
        items.filter { $0.status == .sold }.sorted { ($0.soldAt ?? .distantPast) > ($1.soldAt ?? .distantPast) }
    }

    func itemsForBinder(_ binderID: String) -> [MarketplaceItem] {
        if isOwnStore {
            return activeItems.filter { $0.binderID == binderID }
        }
        return activeItems.filter { $0.binderID == binderID && $0.status != .inactive }
    }

    func visibleItemsForBinder(_ binderID: String) -> [MarketplaceItem] {
        activeItems.filter { $0.binderID == binderID && $0.status != .inactive }
    }

    var unbinderedItems: [MarketplaceItem] {
        if isOwnStore {
            return activeItems.filter { $0.binderID == nil }
        }
        return activeItems.filter { $0.binderID == nil && $0.status != .inactive }
    }

    func cartQuantity(for itemID: String) -> Int {
        inquiryCart.first(where: { $0.item.id == itemID })?.quantity ?? 0
    }

    func canAddToCart(_ item: MarketplaceItem) -> Bool {
        let inCart = cartQuantity(for: item.id)
        return inCart < item.quantity
    }

    func addToCart(_ item: MarketplaceItem) {
        let inCart = cartQuantity(for: item.id)
        guard inCart < item.quantity else {
            appState.showToast("Maximum quantity reached", isError: true)
            return
        }
        if let index = inquiryCart.firstIndex(where: { $0.item.id == item.id }) {
            inquiryCart[index].quantity += 1
        } else {
            inquiryCart.append(InquiryCartItem(item: item, quantity: 1))
        }
        appState.showToast("Added to inquiry")
    }

    func decrementCart(_ itemID: String) {
        guard let index = inquiryCart.firstIndex(where: { $0.item.id == itemID }) else { return }
        if inquiryCart[index].quantity > 1 {
            inquiryCart[index].quantity -= 1
        } else {
            inquiryCart.remove(at: index)
        }
    }

    func incrementCart(_ itemID: String) {
        guard let index = inquiryCart.firstIndex(where: { $0.item.id == itemID }) else { return }
        let item = inquiryCart[index].item
        guard inquiryCart[index].quantity < item.quantity else {
            appState.showToast("Maximum quantity reached", isError: true)
            return
        }
        inquiryCart[index].quantity += 1
    }

    func removeFromCart(_ itemID: String) {
        inquiryCart.removeAll { $0.item.id == itemID }
    }

    func clearCart() {
        inquiryCart.removeAll()
    }

    var cartSummaryMessage: String {
        guard !inquiryCart.isEmpty else { return "" }
        var lines = ["Hi! I'm interested in the following items:\n"]
        for cartItem in inquiryCart {
            let qty = cartItem.quantity > 1 ? " x\(cartItem.quantity)" : ""
            let condStr: String
            if let cond = cartItem.item.condition {
                condStr = " (\(cond.shortName))"
            } else {
                condStr = ""
            }
            lines.append("- \(cartItem.item.displayName)\(condStr) — \(cartItem.item.formattedPrice)\(qty)")
        }
        let total = inquiryCart.reduce(0.0) { $0 + $1.item.priceCAD * Double($1.quantity) }
        lines.append("\nTotal: \(String(format: "$%.2f CAD", total))")
        return lines.joined(separator: "\n")
    }

    var isOwnStore: Bool {
        guard let user = appState.currentUser else { return false }
        return vendor?.userID == user.id
    }

    func saveBinder(_ binder: Binder) async {
        if appState.isMockMode {
            if let idx = binders.firstIndex(where: { $0.id == binder.id }) {
                binders[idx] = binder
            } else {
                binders.append(binder)
            }
            return
        }
        do {
            try await SupabaseService.shared.createBinder(binder)
            await loadStorefront(vendorID: vendor?.userID ?? "")
        } catch {
            appState.showToast("Failed to save binder", isError: true)
        }
    }

    func renameBinder(binderID: String, newName: String) async {
        if appState.isMockMode {
            if let idx = binders.firstIndex(where: { $0.id == binderID }) {
                binders[idx].name = newName
            }
            appState.showToast("Binder renamed")
            return
        }
        do {
            try await SupabaseService.shared.renameBinder(binderID: binderID, newName: newName)
            await loadStorefront(vendorID: vendor?.userID ?? "")
            appState.showToast("Binder renamed")
        } catch {
            appState.showToast("Failed to rename binder", isError: true)
        }
    }

    func saveItem(_ item: MarketplaceItem) async -> Bool {
        if appState.isMockMode {
            if let idx = items.firstIndex(where: { $0.id == item.id }) {
                items[idx] = item
            } else {
                items.append(item)
            }
            return true
        }
        do {
            try await SupabaseService.shared.createItem(item)
            await loadStorefront(vendorID: vendor?.userID ?? "")
            return true
        } catch {
            appState.showToast("Failed to save item", isError: true)
            return false
        }
    }

    // MARK: - Bulk Actions

    func toggleSelection(_ itemID: String) {
        if selectedItemIDs.contains(itemID) {
            selectedItemIDs.remove(itemID)
        } else {
            selectedItemIDs.insert(itemID)
        }
    }

    func exitBulkMode() {
        isBulkMode = false
        selectedItemIDs.removeAll()
    }

    func bulkMarkSold() {
        let changedIDs = Array(selectedItemIDs)
        for id in selectedItemIDs {
            if let idx = items.firstIndex(where: { $0.id == id }) {
                items[idx].status = .sold
                items[idx].soldAt = Date()
            }
        }
        let changedItems = items.filter { changedIDs.contains($0.id) }
        appState.showToast("\(selectedItemIDs.count) item(s) marked sold")
        exitBulkMode()
        if appState.isMockMode { return }

        Task {
            do {
                for item in changedItems {
                    try await SupabaseService.shared.updateItem(item)
                }
            } catch {
                appState.showToast("Failed to save changes", isError: true)
                await loadStorefront(vendorID: vendor?.userID ?? "")
            }
        }
    }

    var bulkHideLabel: String {
        let selectedItems = items.filter { selectedItemIDs.contains($0.id) }
        let allHidden = selectedItems.allSatisfy { $0.status == .inactive }
        return allHidden ? "Unhide" : "Hide"
    }

    var bulkHideIcon: String {
        let selectedItems = items.filter { selectedItemIDs.contains($0.id) }
        let allHidden = selectedItems.allSatisfy { $0.status == .inactive }
        return allHidden ? "eye" : "eye.slash"
    }

    func bulkToggleHide() {
        let changedIDs = Array(selectedItemIDs)
        let selectedItems = items.filter { selectedItemIDs.contains($0.id) }
        let allHidden = selectedItems.allSatisfy { $0.status == .inactive }

        if allHidden {
            for id in selectedItemIDs {
                if let idx = items.firstIndex(where: { $0.id == id }) {
                    items[idx].status = .active
                }
            }
            appState.showToast("\(selectedItemIDs.count) item(s) unhidden")
        } else {
            for id in selectedItemIDs {
                if let idx = items.firstIndex(where: { $0.id == id }) {
                    items[idx].status = .inactive
                }
            }
            appState.showToast("\(selectedItemIDs.count) item(s) hidden")
        }
        let changedItems = items.filter { changedIDs.contains($0.id) }
        exitBulkMode()
        if appState.isMockMode { return }

        Task {
            do {
                for item in changedItems {
                    try await SupabaseService.shared.updateItem(item)
                }
            } catch {
                appState.showToast("Failed to save changes", isError: true)
                await loadStorefront(vendorID: vendor?.userID ?? "")
            }
        }
    }

    func bulkHide() {
        let changedIDs = Array(selectedItemIDs)
        for id in selectedItemIDs {
            if let idx = items.firstIndex(where: { $0.id == id }) {
                items[idx].status = .inactive
            }
        }
        let changedItems = items.filter { changedIDs.contains($0.id) }
        appState.showToast("\(selectedItemIDs.count) item(s) hidden")
        exitBulkMode()
        if appState.isMockMode { return }

        Task {
            do {
                for item in changedItems {
                    try await SupabaseService.shared.updateItem(item)
                }
            } catch {
                appState.showToast("Failed to save changes", isError: true)
                await loadStorefront(vendorID: vendor?.userID ?? "")
            }
        }
    }

    func bulkDelete() {
        let deletedIDs = Array(selectedItemIDs)
        items.removeAll { selectedItemIDs.contains($0.id) }
        appState.showToast("\(selectedItemIDs.count) item(s) deleted")
        exitBulkMode()
        if appState.isMockMode { return }

        Task {
            do {
                for id in deletedIDs {
                    try await SupabaseService.shared.deleteItem(id: id)
                }
            } catch {
                appState.showToast("Failed to save changes", isError: true)
                await loadStorefront(vendorID: vendor?.userID ?? "")
            }
        }
    }

    func bulkMoveToBinder(_ binderID: String) {
        let changedIDs = Array(selectedItemIDs)
        for id in selectedItemIDs {
            if let idx = items.firstIndex(where: { $0.id == id }) {
                items[idx].binderID = binderID
            }
        }
        let changedItems = items.filter { changedIDs.contains($0.id) }
        appState.showToast("\(selectedItemIDs.count) item(s) moved")
        exitBulkMode()
        if appState.isMockMode { return }

        Task {
            do {
                for item in changedItems {
                    try await SupabaseService.shared.updateItem(item)
                }
            } catch {
                appState.showToast("Failed to save changes", isError: true)
                await loadStorefront(vendorID: vendor?.userID ?? "")
            }
        }
    }

    // MARK: - Binder Management

    func toggleBinderHidden(_ binderID: String) {
        if let idx = binders.firstIndex(where: { $0.id == binderID }) {
            binders[idx].isHidden.toggle()
            let hidden = binders[idx].isHidden
            appState.showToast(hidden ? "Binder hidden" : "Binder visible")
            if appState.isMockMode { return }

            let binder = binders[idx]
            Task {
                do {
                    try await SupabaseService.shared.updateBinder(binder)
                } catch {
                    appState.showToast("Failed to save changes", isError: true)
                    await loadStorefront(vendorID: vendor?.userID ?? "")
                }
            }
        }
    }

    func moveBinder(from source: IndexSet, to destination: Int) {
        var sorted = binders.sorted { $0.sortOrder < $1.sortOrder }
        sorted.move(fromOffsets: source, toOffset: destination)
        for (index, _) in sorted.enumerated() {
            sorted[index].sortOrder = index
        }
        binders = sorted
        if appState.isMockMode { return }

        Task {
            do {
                for binder in sorted {
                    try await SupabaseService.shared.updateBinder(binder)
                }
            } catch {
                appState.showToast("Failed to save changes", isError: true)
                await loadStorefront(vendorID: vendor?.userID ?? "")
            }
        }
    }

    func deleteBinder(_ binderID: String, moveItemsTo targetBinderID: String?) {
        let binderItems = items.filter { $0.binderID == binderID }
        if let target = targetBinderID {
            for item in binderItems {
                if let idx = items.firstIndex(where: { $0.id == item.id }) {
                    items[idx].binderID = target
                }
            }
        } else {
            items.removeAll { $0.binderID == binderID }
        }
        binders.removeAll { $0.id == binderID }
        for (index, _) in binders.enumerated() {
            binders[index].sortOrder = index
        }
        appState.showToast("Binder deleted")
        if appState.isMockMode { return }

        Task {
            do {
                if targetBinderID != nil {
                    for item in binderItems {
                        if let updatedItem = items.first(where: { $0.id == item.id }) {
                            try await SupabaseService.shared.updateItem(updatedItem)
                        }
                    }
                }
                try await SupabaseService.shared.deleteBinder(id: binderID)
            } catch {
                appState.showToast("Failed to save changes", isError: true)
                await loadStorefront(vendorID: vendor?.userID ?? "")
            }
        }
    }
}
