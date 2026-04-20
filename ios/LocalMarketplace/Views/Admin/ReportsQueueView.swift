import SwiftUI

struct ReportsQueueView: View {
    let viewModel: AdminViewModel

    var body: some View {
        Group {
            if viewModel.openReports.isEmpty {
                ContentUnavailableView("No Open Reports", systemImage: "flag", description: Text("All reports have been reviewed."))
            } else {
                List(viewModel.openReports) { report in
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Report #\(report.id.prefix(8))")
                                    .font(.subheadline.weight(.semibold))
                                Text("By: \(report.reporterID.prefix(8))...")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            CategoryBadge(text: "Open")
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Reason")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                            Text(report.reason)
                                .font(.subheadline)
                        }

                        if let details = report.details, !details.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Details")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.secondary)
                                Text(details)
                                    .font(.subheadline)
                            }
                        }

                        HStack(spacing: 12) {
                            Button {
                                Task { await viewModel.dismissReport(report) }
                            } label: {
                                Text("Dismiss")
                                    .font(.subheadline.weight(.semibold))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                            }
                            .buttonStyle(.bordered)
                            .clipShape(.capsule)

                            if let vendorID = report.reportedVendorID {
                                Button(role: .destructive) {
                                    Task {
                                        await viewModel.disableVendor(userID: vendorID)
                                        await viewModel.dismissReport(report)
                                    }
                                } label: {
                                    Text("Disable Vendor")
                                        .font(.subheadline.weight(.semibold))
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(.red)
                                .clipShape(.capsule)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
                .listStyle(.insetGrouped)
            }
        }
    }
}
