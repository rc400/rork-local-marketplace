import SwiftUI
import RevenueCatUI

struct SubscriptionStatusView: View {
    let subscriptionService: SubscriptionService
    @State private var showCustomerCenter = false

    var body: some View {
        Section("Subscription") {
            if subscriptionService.isSubscribed {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundStyle(.green)
                            Text(subscriptionService.isTrialActive ? "Free Trial Active" : "Active Subscription")
                                .font(.subheadline.weight(.semibold))
                        }
                        if let plan = subscriptionService.currentPlan {
                            Text("Plan: \(plan.capitalized)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        if let expires = subscriptionService.expirationDate {
                            Text("Renews: \(expires.formatted(date: .abbreviated, time: .omitted))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                }

                Button("Manage Subscription") {
                    showCustomerCenter = true
                }
                .sheet(isPresented: $showCustomerCenter) {
                    CustomerCenterView()
                }
            } else {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    Text("No active subscription")
                        .font(.subheadline)
                }
                Text("Subscribe to go live and reach customers")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
