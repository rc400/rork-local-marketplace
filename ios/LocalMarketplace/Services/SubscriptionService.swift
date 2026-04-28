import Foundation
import RevenueCat

@Observable
@MainActor
class SubscriptionService {
    static let shared = SubscriptionService()

    var isSubscribed: Bool = false
    var currentPlan: String? = nil
    var expirationDate: Date? = nil
    var isTrialActive: Bool = false

    private let entitlementID = "Local Marketplace Vendor"

    /// Call once at app launch
    func configure(appUserID: String?) {
        Purchases.logLevel = .debug
        if let userID = appUserID {
            Purchases.configure(withAPIKey: "test_wMPhIjJGphWxonvHAfhxmAucDvK", appUserID: userID)
        } else {
            Purchases.configure(withAPIKey: "test_wMPhIjJGphWxonvHAfhxmAucDvK")
        }
    }

    /// Identify user (call after login)
    func identify(userID: String) async throws {
        let (customerInfo, _) = try await Purchases.shared.logIn(userID)
        updateSubscriptionStatus(from: customerInfo)
    }

    /// Logout (call on sign out)
    func logout() async throws {
        let customerInfo = try await Purchases.shared.logOut()
        updateSubscriptionStatus(from: customerInfo)
    }

    /// Refresh subscription status
    func refreshStatus() async {
        do {
            let customerInfo = try await Purchases.shared.customerInfo()
            updateSubscriptionStatus(from: customerInfo)
        } catch {
            print("Failed to fetch customer info: \(error)")
        }
    }

    /// Check if vendor has active subscription
    func hasActiveSubscription() async -> Bool {
        do {
            let customerInfo = try await Purchases.shared.customerInfo()
            updateSubscriptionStatus(from: customerInfo)
            return isSubscribed
        } catch {
            return false
        }
    }

    private func updateSubscriptionStatus(from customerInfo: CustomerInfo) {
        let entitlement = customerInfo.entitlements[entitlementID]
        isSubscribed = entitlement?.isActive == true
        currentPlan = entitlement?.productIdentifier
        expirationDate = entitlement?.expirationDate

        if let periodType = entitlement?.periodType {
            isTrialActive = periodType == .trial
        } else {
            isTrialActive = false
        }
    }
}
