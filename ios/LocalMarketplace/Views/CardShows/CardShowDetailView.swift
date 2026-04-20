import SwiftUI

struct CardShowDetailView: View {
    let show: CardShow
    let appState: AppState
    let viewModel: CardShowViewModel
    @State private var selectedStorefrontVendor: Vendor?
    @State private var showEditSheet: Bool = false
    @State private var vendorToRemove: String?
    @Environment(\.dismiss) private var dismiss

    private var creatorVendor: Vendor? {
        viewModel.vendorProfile(for: show.creatorVendorID)
    }

    private var currentShow: CardShow {
        viewModel.cardShows.first { $0.id == show.id } ?? show
    }

    private var sortedAttendeeIDs: [String] {
        let spotlighted = currentShow.attendeeVendorIDs.filter { currentShow.spotlightedVendorIDs.contains($0) }
        let regular = currentShow.attendeeVendorIDs.filter { !currentShow.spotlightedVendorIDs.contains($0) }
        return spotlighted + regular
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                posterHeader

                VStack(alignment: .leading, spacing: 20) {
                    eventInfoSection
                    locationSection
                    organizerSection
                    attendeesSection
                }
                .padding(.horizontal, 16)
                .padding(.top, 20)
                .padding(.bottom, 40)
            }
        }
        .navigationTitle(show.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Close") { dismiss() }
            }
            if viewModel.isCreator(of: currentShow) {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showEditSheet = true
                    } label: {
                        Image(systemName: "pencil.circle.fill")
                    }
                }
            }
        }
        .fullScreenCover(item: $selectedStorefrontVendor) { vendor in
            NavigationStack {
                VendorStorefrontView(vendorID: vendor.userID, appState: appState)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Close") { selectedStorefrontVendor = nil }
                        }
                    }
            }
        }
        .sheet(isPresented: $showEditSheet) {
            EditCardShowView(show: currentShow, viewModel: viewModel)
        }
        .confirmationDialog(
            "Remove Vendor",
            isPresented: Binding(
                get: { vendorToRemove != nil },
                set: { if !$0 { vendorToRemove = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Remove", role: .destructive) {
                if let vendorID = vendorToRemove {
                    viewModel.removeAttendee(vendorID: vendorID, from: show.id)
                }
                vendorToRemove = nil
            }
            Button("Cancel", role: .cancel) {
                vendorToRemove = nil
            }
        } message: {
            Text("Are you sure you want to remove this vendor from the attendees?")
        }
    }

    private var posterHeader: some View {
        Group {
            if let posterURL = currentShow.posterImageURL, let url = URL(string: posterURL) {
                Color(.secondarySystemBackground)
                    .frame(height: 240)
                    .overlay {
                        AsyncImage(url: url) { phase in
                            if let image = phase.image {
                                image.resizable().aspectRatio(contentMode: .fill)
                            } else if phase.error != nil {
                                eventPlaceholderHeader
                            } else {
                                ProgressView()
                            }
                        }
                        .allowsHitTesting(false)
                    }
                    .clipShape(.rect)
                    .overlay(alignment: .bottomLeading) {
                        statusBadge
                            .padding(16)
                    }
            } else {
                eventPlaceholderHeader
            }
        }
    }

    private var eventPlaceholderHeader: some View {
        LinearGradient(
            colors: [.green.opacity(0.4), .green.opacity(0.1)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .frame(height: 200)
        .overlay {
            VStack(spacing: 8) {
                Image(systemName: "party.popper.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(.green)
                Text(currentShow.title)
                    .font(.title2.weight(.bold))
                    .multilineTextAlignment(.center)
            }
        }
        .overlay(alignment: .bottomLeading) {
            statusBadge
                .padding(16)
        }
    }

    private var statusBadge: some View {
        Text(currentShow.statusLabel)
            .font(.caption.weight(.bold))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(currentShow.isHappeningNow ? .green : .orange)
            .foregroundStyle(.white)
            .clipShape(.capsule)
    }

    private var eventInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(currentShow.title)
                .font(.title2.weight(.bold))

            if currentShow.isMultiDay {
                multiDayScheduleView
            } else {
                singleDayInfoView
            }

            if !currentShow.eventDescription.isEmpty {
                Text(currentShow.eventDescription)
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var singleDayInfoView: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Image(systemName: "calendar")
                    .foregroundStyle(.green)
                Text(currentShow.eventDate, format: .dateTime.weekday(.wide).month(.wide).day())
                    .font(.subheadline)
            }

            HStack(spacing: 8) {
                Image(systemName: "clock")
                    .foregroundStyle(.green)
                if let end = currentShow.endTime {
                    Text("\(currentShow.eventDate, format: .dateTime.hour().minute()) – \(end, format: .dateTime.hour().minute())")
                        .font(.subheadline)
                } else {
                    Text(currentShow.eventDate, format: .dateTime.hour().minute())
                        .font(.subheadline)
                }
            }
        }
    }

    private var multiDayScheduleView: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "calendar")
                    .foregroundStyle(.green)
                Text(currentShow.dateDisplayString)
                    .font(.subheadline.weight(.semibold))
                Text("·")
                    .foregroundStyle(.secondary)
                Text("\(currentShow.daySchedules.count) days")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 0) {
                ForEach(currentShow.sortedSchedules) { schedule in
                    HStack(spacing: 12) {
                        Text(schedule.date, format: .dateTime.weekday(.abbreviated).month(.abbreviated).day())
                            .font(.subheadline.weight(.medium))
                            .frame(minWidth: 100, alignment: .leading)

                        Text(schedule.formattedTimeRange)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Spacer()

                        if Calendar.current.isDateInToday(schedule.date) {
                            Text("TODAY")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(.green)
                                .clipShape(.capsule)
                        }
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 12)

                    if schedule.id != currentShow.sortedSchedules.last?.id {
                        Divider()
                            .padding(.leading, 12)
                    }
                }
            }
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(.rect(cornerRadius: 12))
        }
    }

    private var locationSection: some View {
        HStack(spacing: 10) {
            Image(systemName: "mappin.circle.fill")
                .font(.title3)
                .foregroundStyle(.green)

            Text(currentShow.address)
                .font(.subheadline)

            Spacer()
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(.rect(cornerRadius: 12))
    }

    private var organizerSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Organized by")
                .font(.headline)

            if let vendor = creatorVendor {
                Button {
                    selectedStorefrontVendor = vendor
                } label: {
                    HStack(spacing: 12) {
                        vendorAvatar(vendor, size: 44)

                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 4) {
                                Text(vendor.storeName)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.primary)
                                VerifiedBadge()
                            }
                            Text("View Storefront")
                                .font(.caption)
                                .foregroundStyle(.green)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(12)
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(.rect(cornerRadius: 12))
                }
            }
        }
    }

    private var attendeesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Attending Vendors")
                    .font(.headline)
                Spacer()
                Text("\(currentShow.attendeeVendorIDs.count)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            if appState.currentRole == .vendor && !viewModel.isCreator(of: currentShow) {
                Button {
                    viewModel.toggleAttendance(showID: show.id)
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: viewModel.isAttending(currentShow) ? "checkmark.circle.fill" : "plus.circle")
                        Text(viewModel.isAttending(currentShow) ? "You're Attending" : "Mark as Attending")
                    }
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
                .tint(viewModel.isAttending(currentShow) ? .green : .teal)
                .clipShape(.capsule)
            }

            if currentShow.attendeeVendorIDs.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 6) {
                        Image(systemName: "person.2.slash")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                        Text("No vendors attending yet")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 20)
                    Spacer()
                }
            } else {
                ForEach(sortedAttendeeIDs, id: \.self) { vendorID in
                    if let vendor = viewModel.vendorProfile(for: vendorID) {
                        let isSpotlighted = currentShow.spotlightedVendorIDs.contains(vendorID)

                        HStack(spacing: 12) {
                            Button {
                                selectedStorefrontVendor = vendor
                            } label: {
                                HStack(spacing: 12) {
                                    vendorAvatar(vendor, size: 40)

                                    VStack(alignment: .leading, spacing: 2) {
                                        HStack(spacing: 4) {
                                            Text(vendor.storeName)
                                                .font(.subheadline.weight(.semibold))
                                                .foregroundStyle(.primary)
                                            VerifiedBadge()
                                            if isSpotlighted {
                                                SpotlightBadge()
                                            }
                                        }
                                        if !vendor.categories.isEmpty {
                                            Text(vendor.categories.joined(separator: ", "))
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                                .lineLimit(1)
                                        }
                                    }

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }

                            if viewModel.isCreator(of: currentShow) {
                                Button {
                                    viewModel.toggleSpotlight(vendorID: vendorID, in: show.id)
                                } label: {
                                    Image(systemName: isSpotlighted ? "star.fill" : "star")
                                        .foregroundStyle(.yellow)
                                        .font(.body)
                                }
                                .buttonStyle(.plain)

                                Button {
                                    vendorToRemove = vendorID
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(.red.opacity(0.7))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(12)
                        .background(
                            isSpotlighted
                                ? Color.yellow.opacity(0.08)
                                : Color(.secondarySystemGroupedBackground)
                        )
                        .clipShape(.rect(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(isSpotlighted ? Color.yellow.opacity(0.3) : .clear, lineWidth: 1)
                        )
                    }
                }
            }
        }
    }

    private func vendorAvatar(_ vendor: Vendor, size: CGFloat) -> some View {
        Group {
            if let profileURL = vendor.profileImageURL, let url = URL(string: profileURL) {
                Color(.tertiarySystemGroupedBackground)
                    .frame(width: size, height: size)
                    .overlay {
                        AsyncImage(url: url) { phase in
                            if let image = phase.image {
                                image.resizable().aspectRatio(contentMode: .fill)
                            } else {
                                Image(systemName: "storefront.fill")
                                    .foregroundStyle(.teal)
                            }
                        }
                        .allowsHitTesting(false)
                    }
                    .clipShape(Circle())
            } else {
                Circle()
                    .fill(Color.teal.opacity(0.15))
                    .frame(width: size, height: size)
                    .overlay {
                        Image(systemName: "storefront.fill")
                            .font(.caption)
                            .foregroundStyle(.teal)
                    }
            }
        }
    }
}

struct SpotlightBadge: View {
    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: "star.fill")
                .font(.system(size: 8))
            Text("SPOTLIGHT")
                .font(.system(size: 8, weight: .bold))
        }
        .foregroundStyle(.yellow)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(Color.yellow.opacity(0.15))
        .clipShape(.capsule)
    }
}
