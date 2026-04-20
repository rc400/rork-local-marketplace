import Foundation
import SwiftUI

@Observable
@MainActor
class AppState {
    var isAuthenticated: Bool = false
    var currentUser: UserProfile?
    var currentVendor: Vendor?
    var vendorApplication: VendorApplication?
    var isLoading: Bool = false
    var toastMessage: String?
    var toastIsError: Bool = false
    var showNewAccountBanner: Bool = false

    var currentRole: UserRole {
        currentUser?.role ?? .buyer
    }

    var isMockMode: Bool {
        Config.EXPO_PUBLIC_SUPABASE_URL.isEmpty || Config.EXPO_PUBLIC_SUPABASE_ANON_KEY.isEmpty
    }

    func showToast(_ message: String, isError: Bool = false) {
        toastMessage = message
        toastIsError = isError
        Task {
            try? await Task.sleep(for: .seconds(3))
            if toastMessage == message {
                toastMessage = nil
            }
        }
    }

    func signIn(email: String, password: String) async {
        isLoading = true
        defer { isLoading = false }

        if isMockMode {
            currentUser = MockDataService.shared.mockUsers.first { $0.role == .buyer }
            if let user = currentUser, user.role == .vendor {
                currentVendor = MockDataService.shared.vendor(for: user.id)
            }
            isAuthenticated = true
            return
        }

        do {
            currentUser = try await SupabaseService.shared.signIn(email: email, password: password)
            if currentUser?.role == .vendor {
                currentVendor = try await SupabaseService.shared.fetchVendor(userID: currentUser!.id)
            }
            isAuthenticated = true
        } catch {
            showToast("Sign in failed. Please try again.", isError: true)
        }
    }

    func signUp(email: String, password: String, username: String, role: UserRole) async {
        isLoading = true
        defer { isLoading = false }

        if isMockMode {
            currentUser = UserProfile(id: UUID().uuidString, username: username, role: role, isDeleted: false)
            isAuthenticated = true
            return
        }

        do {
            currentUser = try await SupabaseService.shared.signUp(email: email, password: password, username: username, role: role)
            isAuthenticated = true
        } catch let error as SupabaseAPIError {
            showToast(error.localizedDescription, isError: true)
        } catch {
            showToast("Sign up failed: \(error.localizedDescription)", isError: true)
        }
    }

    func signOut() {
        if !isMockMode {
            Task { try? await SupabaseService.shared.signOut() }
        }
        isAuthenticated = false
        currentUser = nil
        currentVendor = nil
        vendorApplication = nil
    }

    func deleteAccount() async {
        guard let user = currentUser else { return }
        isLoading = true
        defer { isLoading = false }

        if !isMockMode {
            try? await SupabaseService.shared.deleteAccount(userID: user.id)
        }
        signOut()
    }

    func mockSignIn(as role: UserRole) {
        currentUser = MockDataService.shared.mockUsers.first { $0.role == role }
        if role == .vendor, let user = currentUser {
            currentVendor = MockDataService.shared.vendor(for: user.id)
            vendorApplication = VendorApplication(id: "app-mock", userID: user.id, status: .approved, contactEmail: "vendor@example.com", contactPhone: "416-555-0100", answersJSON: [:])
        }
        isAuthenticated = true
    }
}
