import SwiftUI

struct MyEventsView: View {
    let appState: AppState
    @State private var viewModel: CardShowViewModel
    @State private var showCreateEvent = false
    @State private var eventToEdit: CardShow?

    init(appState: AppState) {
        self.appState = appState
        _viewModel = State(initialValue: CardShowViewModel(appState: appState))
    }

    private var myEvents: [CardShow] {
        guard let vendor = appState.currentVendor else { return [] }
        return viewModel.cardShows
            .filter { $0.creatorVendorID == vendor.userID }
            .sorted { $0.eventDate > $1.eventDate }
    }

    private var upcomingEvents: [CardShow] {
        myEvents.filter { $0.isUpcoming || $0.isHappeningNow }
    }

    private var pastEvents: [CardShow] {
        myEvents.filter { $0.isPast }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            List {
                if upcomingEvents.isEmpty && pastEvents.isEmpty {
                    Section {
                        ContentUnavailableView {
                            Label("No Events Yet", systemImage: "party.popper")
                        } description: {
                            Text("Create your first Limited Time Event and it will appear here.")
                        }
                    }
                    .listRowBackground(Color.clear)
                }

                if !upcomingEvents.isEmpty {
                    Section("Upcoming") {
                        ForEach(upcomingEvents) { event in
                            NavigationLink {
                                CardShowDetailView(show: event, appState: appState, viewModel: viewModel)
                            } label: {
                                EventRow(event: event)
                            }
                            .swipeActions(edge: .trailing) {
                                Button {
                                    eventToEdit = event
                                } label: {
                                    Label("Edit", systemImage: "pencil")
                                }
                                .tint(.orange)
                            }
                        }
                    }
                }

                if !pastEvents.isEmpty {
                    Section("Past") {
                        ForEach(pastEvents) { event in
                            NavigationLink {
                                CardShowDetailView(show: event, appState: appState, viewModel: viewModel)
                            } label: {
                                EventRow(event: event)
                            }
                        }
                    }
                }

                Color.clear
                    .frame(height: 80)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            }
            .listStyle(.insetGrouped)

            Button {
                showCreateEvent = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                    Text("Create Limited Time Event")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
            .clipShape(.capsule)
            .padding(.horizontal, 20)
            .padding(.bottom, 8)
        }
        .navigationTitle("My Events")
        .task {
            await viewModel.loadCardShows()
        }
        .sheet(isPresented: $showCreateEvent) {
            CreateCardShowView(appState: appState, viewModel: viewModel)
        }
        .sheet(item: $eventToEdit) { event in
            EditCardShowView(show: event, viewModel: viewModel)
        }
        .onChange(of: showCreateEvent) { _, isPresented in
            if !isPresented {
                Task { await viewModel.loadCardShows() }
            }
        }
    }
}

private struct EventRow: View {
    let event: CardShow

    var body: some View {
        HStack(spacing: 14) {
            Circle()
                .fill(event.isPast ? Color.secondary.opacity(0.15) : Color.green.opacity(0.15))
                .frame(width: 48, height: 48)
                .overlay {
                    Image(systemName: "party.popper.fill")
                        .foregroundStyle(event.isPast ? Color.secondary : Color.green)
                }
                .overlay {
                    Circle().stroke(event.isPast ? Color.secondary.opacity(0.3) : Color.green, lineWidth: 2)
                }

            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(event.isPast ? .secondary : .primary)

                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.caption2)
                    if event.isMultiDay {
                        Text(event.dateDisplayString)
                            .font(.caption)
                    } else {
                        Text(event.eventDate, format: .dateTime.month(.abbreviated).day().year().hour().minute())
                            .font(.caption)
                    }
                }
                .foregroundStyle(.secondary)

                HStack(spacing: 8) {
                    CategoryBadge(
                        text: event.statusLabel,
                        style: event.isHappeningNow ? .active : .standard
                    )

                    if !event.attendeeVendorIDs.isEmpty {
                        HStack(spacing: 3) {
                            Image(systemName: "person.2.fill")
                                .font(.system(size: 9))
                            Text("\(event.attendeeVendorIDs.count)")
                                .font(.caption2.weight(.semibold))
                        }
                        .foregroundStyle(.green)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}
