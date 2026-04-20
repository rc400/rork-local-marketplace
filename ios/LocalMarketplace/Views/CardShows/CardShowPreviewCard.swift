import SwiftUI

struct CardShowPreviewCard: View {
    let show: CardShow
    let appState: AppState
    let viewModel: CardShowViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showDetail = false

    private var creatorVendor: Vendor? {
        viewModel.vendorProfile(for: show.creatorVendorID)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 14) {
                HStack(spacing: 12) {
                    if let mapURL = show.mapImageURL, let url = URL(string: mapURL) {
                        Color(.tertiarySystemGroupedBackground)
                            .frame(width: 56, height: 56)
                            .overlay {
                                AsyncImage(url: url) { phase in
                                    if let image = phase.image {
                                        image.resizable().aspectRatio(contentMode: .fill)
                                    } else {
                                        Image(systemName: "party.popper.fill")
                                            .font(.title2)
                                            .foregroundStyle(.green)
                                    }
                                }
                                .allowsHitTesting(false)
                            }
                            .clipShape(Circle())
                            .overlay {
                                Circle().stroke(Color.green, lineWidth: 3)
                            }
                    } else {
                        Circle()
                            .fill(Color.green.opacity(0.15))
                            .frame(width: 56, height: 56)
                            .overlay {
                                Image(systemName: "party.popper.fill")
                                    .font(.title2)
                                    .foregroundStyle(.green)
                            }
                            .overlay {
                                Circle().stroke(Color.green, lineWidth: 3)
                            }
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Text(show.title)
                                .font(.title3.weight(.semibold))
                            CategoryBadge(
                                text: show.statusLabel,
                                style: show.isHappeningNow ? .active : .standard
                            )
                        }

                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            if show.isMultiDay {
                                Text(show.dateDisplayString)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            } else {
                                Text(show.eventDate, format: .dateTime.month(.abbreviated).day().hour().minute())
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }

                    Spacer()
                }

                HStack(spacing: 6) {
                    Image(systemName: "mappin")
                        .font(.caption)
                        .foregroundStyle(.green)
                    Text(show.address)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    Spacer()
                    if !show.attendeeVendorIDs.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "person.2.fill")
                                .font(.caption2)
                            Text("\(show.attendeeVendorIDs.count)")
                                .font(.caption.weight(.semibold))
                        }
                        .foregroundStyle(.green)
                    }
                }

                if let vendor = creatorVendor {
                    HStack(spacing: 6) {
                        Text("by")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(vendor.storeName)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.primary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                Button {
                    showDetail = true
                } label: {
                    Label("View Limited Time Event", systemImage: "party.popper")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
                .clipShape(.capsule)
            }
            .padding(20)
            .fullScreenCover(isPresented: $showDetail) {
                NavigationStack {
                    CardShowDetailView(show: show, appState: appState, viewModel: viewModel)
                }
            }
        }
    }
}
