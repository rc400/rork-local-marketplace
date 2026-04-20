import Foundation

nonisolated struct CardShow: Codable, Identifiable, Sendable, Hashable {
    let id: String
    var creatorVendorID: String
    var title: String
    var eventDescription: String
    var eventDate: Date
    var endTime: Date?
    var isMultiDay: Bool
    var daySchedules: [EventDaySchedule]
    var visibleOnMapDate: Date?
    var address: String
    var lat: Double?
    var lng: Double?
    var mapImageURL: String?
    var posterImageURL: String?
    var attendeeVendorIDs: [String]
    var spotlightedVendorIDs: [String]
    var createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, title, address, lat, lng
        case creatorVendorID = "creator_vendor_id"
        case eventDescription = "event_description"
        case eventDate = "event_date"
        case endTime = "end_time"
        case isMultiDay = "is_multi_day"
        case daySchedules = "day_schedules"
        case visibleOnMapDate = "visible_on_map_date"
        case mapImageURL = "map_image_url"
        case posterImageURL = "poster_image_url"
        case attendeeVendorIDs = "attendee_vendor_ids"
        case spotlightedVendorIDs = "spotlighted_vendor_ids"
        case createdAt = "created_at"
    }

    init(id: String, creatorVendorID: String, title: String, eventDescription: String, eventDate: Date, endTime: Date? = nil, isMultiDay: Bool = false, daySchedules: [EventDaySchedule] = [], visibleOnMapDate: Date? = nil, address: String, lat: Double? = nil, lng: Double? = nil, mapImageURL: String? = nil, posterImageURL: String? = nil, attendeeVendorIDs: [String], spotlightedVendorIDs: [String], createdAt: Date? = nil) {
        self.id = id
        self.creatorVendorID = creatorVendorID
        self.title = title
        self.eventDescription = eventDescription
        self.eventDate = eventDate
        self.endTime = endTime
        self.isMultiDay = isMultiDay
        self.daySchedules = daySchedules
        self.visibleOnMapDate = visibleOnMapDate
        self.address = address
        self.lat = lat
        self.lng = lng
        self.mapImageURL = mapImageURL
        self.posterImageURL = posterImageURL
        self.attendeeVendorIDs = attendeeVendorIDs
        self.spotlightedVendorIDs = spotlightedVendorIDs
        self.createdAt = createdAt
    }

    var firstDate: Date {
        if isMultiDay, let first = sortedSchedules.first {
            return first.date
        }
        return eventDate
    }

    var lastDate: Date {
        if isMultiDay, let last = sortedSchedules.last {
            return last.date
        }
        return eventDate
    }

    var lastEndTime: Date {
        if isMultiDay, let last = sortedSchedules.last {
            return last.endTime
        }
        return endTime ?? Calendar.current.startOfDay(for: eventDate).addingTimeInterval(24 * 3600)
    }

    var sortedSchedules: [EventDaySchedule] {
        daySchedules.sorted { $0.date < $1.date }
    }

    var isHappeningNow: Bool {
        let now = Date()
        if isMultiDay {
            return sortedSchedules.contains { schedule in
                let calendar = Calendar.current
                return calendar.isDate(now, inSameDayAs: schedule.date) && now >= schedule.startTime && now <= schedule.endTime
            }
        }
        if let end = endTime {
            return now >= eventDate && now <= end
        }
        return Calendar.current.isDateInToday(eventDate)
    }

    var isUpcoming: Bool {
        firstDate > Date() && !isHappeningNow
    }

    var isPast: Bool {
        Date() > lastEndTime
    }

    var shouldShowOnMap: Bool {
        let visibleFrom = visibleOnMapDate ?? firstDate.addingTimeInterval(-7 * 24 * 3600)
        return Date() >= visibleFrom && Date() <= lastEndTime
    }

    var daysUntilEvent: Int? {
        guard isUpcoming else { return nil }
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: calendar.startOfDay(for: Date()), to: calendar.startOfDay(for: firstDate))
        return components.day
    }

    var statusLabel: String {
        if isHappeningNow { return "Happening Now" }
        if let days = daysUntilEvent {
            if days == 0 { return "Today" }
            if days == 1 { return "Tomorrow" }
            return "In \(days) days"
        }
        if isPast { return "Past Event" }
        return "Scheduled"
    }

    var dateDisplayString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        if isMultiDay, let first = sortedSchedules.first, let last = sortedSchedules.last {
            if Calendar.current.isDate(first.date, equalTo: last.date, toGranularity: .month) {
                let dayFormatter = DateFormatter()
                dayFormatter.dateFormat = "d"
                return "\(formatter.string(from: first.date))–\(dayFormatter.string(from: last.date))"
            }
            return "\(formatter.string(from: first.date)) – \(formatter.string(from: last.date))"
        }
        return formatter.string(from: eventDate)
    }
}
