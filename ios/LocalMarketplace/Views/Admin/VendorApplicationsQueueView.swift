import SwiftUI

struct VendorApplicationsQueueView: View {
    let viewModel: AdminViewModel
    @State private var rejectNote = ""
    @State private var appToReject: VendorApplication?

    var body: some View {
        Group {
            if viewModel.pendingApplications.isEmpty {
                ContentUnavailableView("No Pending Applications", systemImage: "checkmark.circle", description: Text("All vendor applications have been reviewed."))
            } else {
                List(viewModel.pendingApplications) { app in
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("User: \(app.userID)")
                                    .font(.subheadline.weight(.semibold))
                                Text(app.contactEmail)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                if !app.contactPhone.isEmpty {
                                    Text(app.contactPhone)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                            CategoryBadge(text: "Pending")
                        }

                        ForEach(Array(app.answersJSON.sorted(by: { $0.key < $1.key })), id: \.key) { key, value in
                            VStack(alignment: .leading, spacing: 2) {
                                Text(key.replacingOccurrences(of: "_", with: " ").capitalized)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.secondary)
                                Text(value)
                                    .font(.subheadline)
                            }
                        }

                        HStack(spacing: 12) {
                            Button {
                                Task { await viewModel.approveApplication(app) }
                            } label: {
                                Label("Approve", systemImage: "checkmark")
                                    .font(.subheadline.weight(.semibold))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.green)
                            .clipShape(.capsule)

                            Button {
                                appToReject = app
                            } label: {
                                Label("Reject", systemImage: "xmark")
                                    .font(.subheadline.weight(.semibold))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                            }
                            .buttonStyle(.bordered)
                            .tint(.red)
                            .clipShape(.capsule)
                        }
                    }
                    .padding(.vertical, 8)
                }
                .listStyle(.insetGrouped)
            }
        }
        .alert("Reject Application", isPresented: Binding(
            get: { appToReject != nil },
            set: { if !$0 { appToReject = nil } }
        )) {
            TextField("Reason (optional)", text: $rejectNote)
            Button("Reject", role: .destructive) {
                if let app = appToReject {
                    Task { await viewModel.rejectApplication(app, note: rejectNote.isEmpty ? nil : rejectNote) }
                }
                rejectNote = ""
                appToReject = nil
            }
            Button("Cancel", role: .cancel) {
                rejectNote = ""
                appToReject = nil
            }
        }
    }
}
