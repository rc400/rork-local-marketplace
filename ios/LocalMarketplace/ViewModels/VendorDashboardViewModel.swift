import Foundation

@Observable
@MainActor
class VendorDashboardViewModel {
    var vendor: Vendor?
    var hasActiveItems: Bool = false
    var isTogglingActive: Bool = false
    var showDurationPicker: Bool = false
    var selectedDuration: ActiveDuration = .fourHours

    private let appState: AppState

    init(appState: AppState) {
        self.appState = appState
        self.vendor = appState.currentVendor
    }

    var canToggleActive: Bool {
        guard let v = vendor else { return false }
        return v.approved && !v.isDisabled && v.hasRequiredFields && hasActiveItems
    }

    var statusMessage: String {
        guard let v = vendor else { return "" }
        if v.isDisabled { return "Your account has been disabled by an admin." }
        if !v.approved { return "Pending approval" }
        if !v.hasRequiredFields { return "Complete your storefront to go active" }
        if !hasActiveItems { return "Add at least one active item to go live" }
        if v.isActive {
            if let until = v.activeUntil {
                let formatter = RelativeDateTimeFormatter()
                formatter.unitsStyle = .abbreviated
                return "Active \u{2022} ends \(formatter.localizedString(for: until, relativeTo: Date()))"
            }
            return "Active"
        }
        return "Inactive"
    }

    func loadVendorState() async {
        guard let user = appState.currentUser else { return }

        if appState.isMockMode {
            vendor = appState.currentVendor
            hasActiveItems = MockDataService.shared.vendorItems(vendorID: user.id).contains { $0.status == .active }
            checkExpiry()
            return
        }

        do {
            vendor = try await SupabaseService.shared.fetchVendor(userID: user.id)
            let items = try await SupabaseService.shared.fetchItems(vendorID: user.id)
            hasActiveItems = items.contains { $0.status == .active }
            appState.currentVendor = vendor
            checkExpiry()
        } catch {
            appState.showToast("Failed to load vendor status", isError: true)
        }
    }

    func toggleActive(duration: ActiveDuration) async {
        guard var v = vendor else { return }
        isTogglingActive = true
        defer { isTogglingActive = false }

        v.isActive = true
        v.activeUntil = Date().addingTimeInterval(TimeInterval(duration.rawValue) * 3600)
        vendor = v
        appState.currentVendor = v

        if !appState.isMockMode {
            try? await SupabaseService.shared.updateVendor(v)
        }
    }

    func deactivate() async {
        guard var v = vendor else { return }
        v.isActive = false
        v.activeUntil = nil
        vendor = v
        appState.currentVendor = v

        if !appState.isMockMode {
            try? await SupabaseService.shared.updateVendor(v)
        }
    }

    private func checkExpiry() {
        guard var v = vendor, v.isActive, v.isExpired else { return }
        v.isActive = false
        v.activeUntil = nil
        vendor = v
        appState.currentVendor = v
    }
}
