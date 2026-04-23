import SwiftUI

@main
struct LocalMarketplaceApp: App {
    @State private var appState = AppState()

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
