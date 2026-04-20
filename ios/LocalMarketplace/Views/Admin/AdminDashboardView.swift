import SwiftUI

struct AdminDashboardView: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel: AdminViewModel
    @State private var selectedTab: AdminTab = .applications

    enum AdminTab: String, CaseIterable {
        case applications = "Applications"
        case reports = "Reports"
        case users = "Users"

        var icon: String {
            switch self {
            case .applications: "doc.text.fill"
            case .reports: "flag.fill"
            case .users: "person.2.fill"
            }
        }
    }

    init(appState: AppState) {
        _viewModel = State(initialValue: AdminViewModel(appState: appState))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Section", selection: $selectedTab) {
                    ForEach(AdminTab.allCases, id: \.self) { tab in
                        Label(tab.rawValue, systemImage: tab.icon).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)

                Group {
                    switch selectedTab {
                    case .applications:
                        VendorApplicationsQueueView(viewModel: viewModel)
                    case .reports:
                        ReportsQueueView(viewModel: viewModel)
                    case .users:
                        UserManagementView(viewModel: viewModel)
                    }
                }
            }
            .navigationTitle("Admin")
            .task {
                await viewModel.loadDashboard()
            }
            .refreshable {
                await viewModel.loadDashboard()
            }
            .overlay {
                if viewModel.isLoading {
                    ProgressView()
                }
            }
        }
    }
}
