import SwiftUI
import RevenueCat

@main
struct LocalMarketplaceApp: App {
    @State private var appState = AppState()

    init() {
        SubscriptionService.shared.configure(appUserID: nil)
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView()
                    .environment(appState)

                if appState.isRestoringSession {
                    ProgressView()
                        .controlSize(.large)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(.background)
                }
            }
            .task {
                await appState.restoreSession()
            }
        }
    }
}
