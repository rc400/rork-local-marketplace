import SwiftUI
import MapKit
import PhotosUI

struct EditCardShowView: View {
    @Environment(\.dismiss) private var dismiss
    let show: CardShow
    let viewModel: CardShowViewModel

    @State private var title: String
    @State private var eventDescription: String
    @State private var eventDate: Date
    @State private var endTime: Date
    @State private var isMultiDay: Bool
    @State private var daySchedules: [EventDaySchedule]
    @State private var multiDayStartDate: Date
    @State private var multiDayEndDate: Date
    @State private var visibleOnMapDate: Date
    @State private var address: String
    @State private var mapImageData: Data?
    @State private var posterImageData: Data?
    @State private var currentMapURL: String?
    @State private var currentPosterURL: String?
    @State private var searchCompleter = AddressSearchCompleter()
    @State private var showSuggestions: Bool = false
    @State private var isSaving: Bool = false

    init(show: CardShow, viewModel: CardShowViewModel) {
        self.show = show
        self.viewModel = viewModel
        _title = State(initialValue: show.title)
        _eventDescription = State(initialValue: show.eventDescription)
        _eventDate = State(initialValue: show.eventDate)
        _endTime = State(initialValue: show.endTime ?? show.eventDate.addingTimeInterval(4 * 3600))
        _isMultiDay = State(initialValue: show.isMultiDay)
        _daySchedules = State(initialValue: show.daySchedules)
        let sorted = show.sortedSchedules
        _multiDayStartDate = State(initialValue: sorted.first?.date ?? show.eventDate)
        _multiDayEndDate = State(initialValue: sorted.last?.date ?? show.eventDate)
        _visibleOnMapDate = State(initialValue: show.visibleOnMapDate ?? show.eventDate.addingTimeInterval(-7 * 24 * 3600))
        _address = State(initialValue: show.address)
        _currentMapURL = State(initialValue: show.mapImageURL)
        _currentPosterURL = State(initialValue: show.posterImageURL)
    }

    private var canSave: Bool {
        !title.isEmpty && !address.isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Event Details") {
                    TextField("Event Title", text: $title)

                    Toggle("Multi-Day Event", isOn: $isMultiDay)
                        .tint(.green)

                    if isMultiDay {
                        multiDaySection
                    } else {
                        singleDaySection
                    }

                    DatePicker("Visible on Map From", selection: $visibleOnMapDate, in: ...firstEventDate, displayedComponents: [.date])

                    TextField("Description", text: $eventDescription, axis: .vertical)
                        .lineLimit(3...8)
                }

                if isMultiDay && !daySchedules.isEmpty {
                    Section("Daily Schedule") {
                        ForEach(Array(daySchedules.enumerated()), id: \.element.id) { index, schedule in
                            DayScheduleRow(schedule: $daySchedules[index])
                        }
                    }
                }

                Section("Location") {
                    TextField("Search address…", text: $address)
                        .onChange(of: address) { _, newValue in
                            searchCompleter.search(query: newValue)
                            showSuggestions = !newValue.isEmpty
                        }

                    if showSuggestions && !searchCompleter.results.isEmpty {
                        ForEach(searchCompleter.results, id: \.self) { completion in
                            Button {
                                address = [completion.title, completion.subtitle]
                                    .filter { !$0.isEmpty }
                                    .joined(separator: ", ")
                                showSuggestions = false
                            } label: {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(completion.title)
                                        .font(.subheadline)
                                        .foregroundStyle(.primary)
                                    if !completion.subtitle.isEmpty {
                                        Text(completion.subtitle)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                    }
                }

                Section {
                    ImagePickerButton(
                        label: "Choose Map Image",
                        currentURL: currentMapURL,
                        imageData: $mapImageData,
                        shape: .circle
                    )
                } header: {
                    Text("Map Image")
                } footer: {
                    Text("This image appears on the map inside a green circle.")
                }

                Section {
                    ImagePickerButton(
                        label: "Choose Poster Image",
                        currentURL: currentPosterURL,
                        imageData: $posterImageData,
                        shape: .roundedRect
                    )
                } header: {
                    Text("Poster Image")
                } footer: {
                    Text("A larger image shown in the event detail view.")
                }
            }
            .navigationTitle("Edit Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .disabled(isSaving)
                }
                ToolbarItem(placement: .confirmationAction) {
                    if isSaving {
                        ProgressView()
                    } else {
                        Button("Save") { saveChanges() }
                            .disabled(!canSave)
                    }
                }
            }
            .onChange(of: isMultiDay) { _, newValue in
                if newValue && daySchedules.isEmpty { generateDaySchedules() }
            }
            .onChange(of: multiDayStartDate) { _, _ in
                if isMultiDay { generateDaySchedules() }
            }
            .onChange(of: multiDayEndDate) { _, _ in
                if isMultiDay { generateDaySchedules() }
            }
        }
    }

    private var firstEventDate: Date {
        if isMultiDay, let first = daySchedules.sorted(by: { $0.date < $1.date }).first {
            return first.date
        }
        return eventDate
    }

    private var singleDaySection: some View {
        Group {
            DatePicker("Start", selection: $eventDate, displayedComponents: [.date, .hourAndMinute])
            DatePicker("End", selection: $endTime, in: eventDate..., displayedComponents: [.hourAndMinute])
        }
    }

    private var multiDaySection: some View {
        Group {
            DatePicker("First Day", selection: $multiDayStartDate, displayedComponents: [.date])
            DatePicker("Last Day", selection: $multiDayEndDate, in: multiDayStartDate..., displayedComponents: [.date])

            HStack {
                Image(systemName: "calendar.badge.clock")
                    .foregroundStyle(.green)
                Text("\(daySchedules.count) day\(daySchedules.count == 1 ? "" : "s")")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func generateDaySchedules() {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: multiDayStartDate)
        let end = calendar.startOfDay(for: multiDayEndDate)

        var dates: [Date] = []
        var current = start
        while current <= end {
            dates.append(current)
            guard let next = calendar.date(byAdding: .day, value: 1, to: current) else { break }
            current = next
        }

        if dates.count > 14 { dates = Array(dates.prefix(14)) }

        let existingByDay: [String: EventDaySchedule] = Dictionary(
            uniqueKeysWithValues: daySchedules.compactMap { schedule in
                let key = calendar.startOfDay(for: schedule.date).description
                return (key, schedule)
            }
        )

        daySchedules = dates.map { date in
            let key = date.description
            if let existing = existingByDay[key] { return existing }
            let defaultStart = calendar.date(bySettingHour: 10, minute: 0, second: 0, of: date) ?? date
            let defaultEnd = calendar.date(bySettingHour: 17, minute: 0, second: 0, of: date) ?? date
            return EventDaySchedule(id: UUID().uuidString, date: date, startTime: defaultStart, endTime: defaultEnd)
        }
    }

    private func saveChanges() {
        isSaving = true
        Task {
            var mapURL = currentMapURL
            var posterURL = currentPosterURL

            if let data = mapImageData, !viewModel.appState.isMockMode {
                mapURL = try? await SupabaseService.shared.uploadImage(bucket: "events", folder: show.id, imageData: data)
            }
            if let data = posterImageData, !viewModel.appState.isMockMode {
                posterURL = try? await SupabaseService.shared.uploadImage(bucket: "events", folder: "\(show.id)/poster", imageData: data)
            }

            let finalEventDate = isMultiDay ? (daySchedules.sorted { $0.date < $1.date }.first?.startTime ?? multiDayStartDate) : eventDate
            let finalEndTime: Date? = isMultiDay ? nil : endTime

            await viewModel.updateCardShowDetails(
                showID: show.id,
                title: title,
                eventDescription: eventDescription,
                eventDate: finalEventDate,
                endTime: finalEndTime,
                isMultiDay: isMultiDay,
                daySchedules: isMultiDay ? daySchedules : [],
                visibleOnMapDate: visibleOnMapDate,
                address: address,
                mapImageURL: mapURL,
                posterImageURL: posterURL
            )
            isSaving = false
            dismiss()
        }
    }
}
