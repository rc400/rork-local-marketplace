import SwiftUI
import RevenueCat
import RevenueCatUI

struct VendorPaywallView: View {
    @Environment(\.dismiss) private var dismiss
    let onSubscribed: () -> Void

    var body: some View {
        PaywallView(displayCloseButton: true)
            .onPurchaseCompleted { customerInfo in
                onSubscribed()
                dismiss()
            }
            .onRestoreCompleted { customerInfo in
                let entitlement = customerInfo.entitlements["Local Marketplace Vendor"]
                if entitlement?.isActive == true {
                    onSubscribed()
                    dismiss()
                }
            }
    }
}
