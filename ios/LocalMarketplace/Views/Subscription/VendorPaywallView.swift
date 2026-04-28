import SwiftUI
import RevenueCatUI

struct VendorPaywallView: View {
    @Environment(\.dismiss) private var dismiss
    let onSubscribed: () -> Void

    var body: some View {
        PaywallView(
            displayCloseButton: true,
            purchaseCompleted: { customerInfo in
                onSubscribed()
                dismiss()
            },
            restoreCompleted: { customerInfo in
                let entitlement = customerInfo.entitlements["Local Marketplace Vendor"]
                if entitlement?.isActive == true {
                    onSubscribed()
                    dismiss()
                }
            }
        )
    }
}
