import Foundation
import UIKit

@Observable
@MainActor
class ProfileViewModel {
    var followedVendors: [Vendor] = []
    var notificationPrefs: NotificationPrefs?
    var isLoading: Bool = false
    var isSaving: Bool = false

    var editDisplayName: String = ""
    var editBio: String = ""
    var avatarImageData: Data?

    private let appState: AppState

    init(appState: AppState) {
        self.appState = appState
    }

    func loadProfile() async {
        guard let user = appState.currentUser else { return }
        isLoading = true
        defer { isLoading = false }

        if appState.isMockMode {
            followedVendors = Array(MockDataService.shared.mockVendors.prefix(2))
            notificationPrefs = NotificationPrefs(userID: user.id, pushEnabled: false)
            return
        }

        do {
            let freshProfile = try await SupabaseService.shared.fetchProfile(userID: user.id)
            appState.currentUser = freshProfile
            syncEditFields(from: freshProfile)

            let follows = try await SupabaseService.shared.fetchFollows(followerID: user.id)
            var vendors: [Vendor] = []
            for follow in follows {
                if let vendor = try await SupabaseService.shared.fetchVendor(userID: follow.vendorID) {
                    vendors.append(vendor)
                }
            }
            followedVendors = vendors
            notificationPrefs = try await SupabaseService.shared.fetchNotificationPrefs(userID: user.id)
        } catch {
            appState.showToast("Failed to load profile", isError: true)
        }
    }

    func syncEditFields(from profile: UserProfile) {
        editDisplayName = profile.displayName ?? ""
        editBio = profile.bio ?? ""
        avatarImageData = nil
    }

    func saveProfile() async {
        guard var user = appState.currentUser else { return }
        isSaving = true
        defer { isSaving = false }

        do {
            if let imageData = avatarImageData {
                let compressed = compressImage(imageData)
                let avatarURL = try await SupabaseService.shared.uploadAvatar(userID: user.id, imageData: compressed)
                user.avatarURL = avatarURL
            }

            user.displayName = editDisplayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : editDisplayName.trimmingCharacters(in: .whitespacesAndNewlines)
            user.bio = editBio.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : editBio.trimmingCharacters(in: .whitespacesAndNewlines)

            try await SupabaseService.shared.updateProfileFields(
                userID: user.id,
                displayName: user.displayName,
                bio: user.bio,
                avatarURL: user.avatarURL
            )

            appState.currentUser = user
            avatarImageData = nil
            appState.showToast("Profile updated")
        } catch {
            appState.showToast("Failed to save profile: \(error.localizedDescription)", isError: true)
        }
    }

    func toggleNotifications(enabled: Bool) async {
        guard let user = appState.currentUser else { return }
        notificationPrefs?.pushEnabled = enabled

        if !appState.isMockMode {
            let prefs = NotificationPrefs(userID: user.id, pushEnabled: enabled)
            try? await SupabaseService.shared.updateNotificationPrefs(prefs)
        }
    }

    private func compressImage(_ data: Data) -> Data {
        guard let image = UIImage(data: data) else { return data }
        return image.jpegData(compressionQuality: 0.7) ?? data
    }
}
