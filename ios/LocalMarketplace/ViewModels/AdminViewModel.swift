import Foundation

@Observable
@MainActor
class AdminViewModel {
    var pendingApplications: [VendorApplication] = []
    var openReports: [Report] = []
    var searchResults: [UserProfile] = []
    var searchQuery: String = ""
    var isLoading: Bool = false

    private let appState: AppState

    init(appState: AppState) {
        self.appState = appState
    }

    func loadDashboard() async {
        isLoading = true
        defer { isLoading = false }

        if appState.isMockMode {
            pendingApplications = MockDataService.shared.mockApplications.filter { $0.status == .pending }
            openReports = MockDataService.shared.mockReports.filter { $0.status == .open }
            return
        }

        do {
            pendingApplications = try await SupabaseService.shared.fetchVendorApplications(status: .pending)
            openReports = try await SupabaseService.shared.fetchReports(status: .open)
        } catch {
            appState.showToast("Failed to load dashboard", isError: true)
        }
    }

    func approveApplication(_ app: VendorApplication) async {
        if appState.isMockMode {
            pendingApplications.removeAll { $0.id == app.id }
            appState.showToast("Application approved")
            return
        }

        do {
            try await SupabaseService.shared.updateApplicationStatus(id: app.id, status: .approved, note: nil)
            pendingApplications.removeAll { $0.id == app.id }
            appState.showToast("Application approved")
        } catch {
            appState.showToast("Failed to approve", isError: true)
        }
    }

    func rejectApplication(_ app: VendorApplication, note: String?) async {
        if appState.isMockMode {
            pendingApplications.removeAll { $0.id == app.id }
            appState.showToast("Application rejected")
            return
        }

        do {
            try await SupabaseService.shared.updateApplicationStatus(id: app.id, status: .rejected, note: note)
            pendingApplications.removeAll { $0.id == app.id }
            appState.showToast("Application rejected")
        } catch {
            appState.showToast("Failed to reject", isError: true)
        }
    }

    func dismissReport(_ report: Report) async {
        if appState.isMockMode {
            openReports.removeAll { $0.id == report.id }
            appState.showToast("Report dismissed")
            return
        }

        do {
            try await SupabaseService.shared.updateReportStatus(id: report.id, status: .closed)
            openReports.removeAll { $0.id == report.id }
        } catch {
            appState.showToast("Failed to dismiss report", isError: true)
        }
    }

    func disableVendor(userID: String) async {
        if !appState.isMockMode {
            try? await SupabaseService.shared.disableVendor(userID: userID)
        }
        appState.showToast("Vendor disabled")
    }

    func searchUsers() async {
        guard !searchQuery.trimmingCharacters(in: .whitespaces).isEmpty else { return }

        if appState.isMockMode {
            searchResults = MockDataService.shared.mockUsers.filter {
                $0.username.localizedStandardContains(searchQuery)
            }
            return
        }

        do {
            searchResults = try await SupabaseService.shared.searchUsers(query: searchQuery)
        } catch {
            appState.showToast("Search failed", isError: true)
        }
    }

    func promoteToAdmin(userID: String) async {
        if appState.isMockMode {
            if let idx = searchResults.firstIndex(where: { $0.id == userID }) {
                searchResults[idx] = UserProfile(id: searchResults[idx].id, username: searchResults[idx].username, avatarURL: searchResults[idx].avatarURL, role: .admin, isDeleted: false)
            }
            appState.showToast("User promoted to admin")
            return
        }

        do {
            try await SupabaseService.shared.promoteToAdmin(userID: userID)
            appState.showToast("User promoted to admin")
            await searchUsers()
        } catch {
            appState.showToast("Failed to promote user", isError: true)
        }
    }
}
