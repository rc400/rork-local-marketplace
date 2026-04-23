import SwiftUI

struct ReportSheetView: View {
    @Environment(\.dismiss) private var dismiss
    let appState: AppState

    var reportedUserID: String?
    var reportedVendorID: String?
    var conversationID: String?

    @State private var reason = ""
    @State private var details = ""

    init(reportedUserID: String? = nil, reportedVendorID: String? = nil, conversationID: String? = nil, appState: AppState) {
        self.reportedUserID = reportedUserID
        self.reportedVendorID = reportedVendorID
        self.conversationID = conversationID
        self.appState = appState
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Reason") {
                    Picker("Select a reason", selection: $reason) {
                        Text("Select...").tag("")
                        Text("Spam or scam").tag("Spam or scam")
                        Text("Inappropriate content").tag("Inappropriate content")
                        Text("Suspicious pricing").tag("Suspicious pricing")
                        Text("Harassment").tag("Harassment")
                        Text("Other").tag("Other")
                    }
                }

                Section("Details") {
                    TextField("Provide additional details...", text: $details, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Report")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Submit") {
                        submitReport()
                    }
                    .disabled(reason.isEmpty)
                }
            }
        }
    }

    private func submitReport() {
        guard let reporterID = appState.currentUser?.id else {
            appState.showToast("Failed to submit report", isError: true)
            return
        }

        let report = Report(
            id: UUID().uuidString,
            reporterID: reporterID,
            reportedUserID: reportedUserID,
            reportedVendorID: reportedVendorID,
            conversationID: conversationID,
            reason: reason,
            details: details.isEmpty ? nil : details,
            status: .open,
            createdAt: Date(),
            updatedAt: Date()
        )

        Task {
            do {
                try await SupabaseService.shared.submitReport(report)
                appState.showToast("Report submitted")
                dismiss()
            } catch {
                appState.showToast("Failed to submit report", isError: true)
            }
        }
    }
}
