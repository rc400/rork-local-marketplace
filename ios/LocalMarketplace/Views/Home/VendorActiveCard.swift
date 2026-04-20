import SwiftUI

struct VendorActiveCard: View {
    let appState: AppState
    @State private var viewModel: VendorDashboardViewModel
    @State private var showDurationPicker = false
    @State private var showMissingItemsAlert = false
    init(appState: AppState) {
        self.appState = appState
        _viewModel = State(initialValue: VendorDashboardViewModel(appState: appState))
    }

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(viewModel.vendor?.isActive == true ? .green : .secondary.opacity(0.4))
                            .frame(width: 10, height: 10)
                        Text(viewModel.vendor?.isActive == true ? "Active" : "Inactive")
                            .font(.subheadline.weight(.semibold))
                    }

                    Text(viewModel.statusMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                if viewModel.vendor?.isActive == true {
                    Button {
                        Task { await viewModel.deactivate() }
                    } label: {
                        Text("Go Offline")
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                    .clipShape(.capsule)
                } else {
                    Button {
                        if !viewModel.canToggleActive {
                            if !viewModel.hasActiveItems {
                                showMissingItemsAlert = true
                            }
                        } else {
                            showDurationPicker = true
                        }
                    } label: {
                        Text("Go Live")
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.teal)
                    .clipShape(.capsule)
                    .disabled(!viewModel.canToggleActive && viewModel.hasActiveItems)
                }
            }
        }
        .padding(14)
        .background(.ultraThinMaterial, in: .rect(cornerRadius: 14))
        .task {
            await viewModel.loadVendorState()
        }
        .confirmationDialog("How long do you want to be active?", isPresented: $showDurationPicker, titleVisibility: .visible) {
            ForEach(ActiveDuration.allCases, id: \.rawValue) { duration in
                Button(duration.fullDisplayName) {
                    Task { await viewModel.toggleActive(duration: duration) }
                }
            }
            Button("Cancel", role: .cancel) {}
        }
        .alert("Add Inventory First", isPresented: $showMissingItemsAlert) {
            Button("OK") {}
        } message: {
            Text("You must have at least one active item in your storefront before going live.")
        }
    }
}
