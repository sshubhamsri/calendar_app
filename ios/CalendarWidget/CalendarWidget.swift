import WidgetKit
import SwiftUI

// MARK: - Data Models

struct WidgetEvent: Identifiable, Decodable {
    let id = UUID()
    let title: String
    let start: String
    let color: Int
    let isHoliday: Bool
    let isAllDay: Bool

    var startDate: Date? {
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: start)
    }

    var swiftColor: Color {
        let argb = color
        let r = Double((argb >> 16) & 0xFF) / 255.0
        let g = Double((argb >> 8) & 0xFF) / 255.0
        let b = Double(argb & 0xFF) / 255.0
        return Color(red: r, green: g, blue: b)
    }

    private enum CodingKeys: String, CodingKey {
        case title, start, color, isHoliday, isAllDay
    }
}

struct WidgetWeather: Decodable {
    let date: String
    let iconCode: String
    let tempMax: Double
}

struct CalendarEntry: TimelineEntry {
    let date: Date
    let monthLabel: String
    let todayDay: Int
    let events: [WidgetEvent]
    let weather: [WidgetWeather]
}

// MARK: - Timeline Provider

struct CalendarTimelineProvider: TimelineProvider {
    private let appGroupId = "group.com.naehas.calendar_app"

    func placeholder(in context: Context) -> CalendarEntry {
        CalendarEntry(
            date: Date(),
            monthLabel: "MAR",
            todayDay: Calendar.current.component(.day, from: Date()),
            events: [],
            weather: []
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (CalendarEntry) -> Void) {
        completion(makeEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CalendarEntry>) -> Void) {
        let entry = makeEntry()
        // Refresh every 15 minutes
        let nextRefresh = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date()
        let timeline = Timeline(entries: [entry], policy: .after(nextRefresh))
        completion(timeline)
    }

    private func makeEntry() -> CalendarEntry {
        let defaults = UserDefaults(suiteName: appGroupId)

        let monthFormatter = DateFormatter()
        monthFormatter.dateFormat = "MMM"
        let monthLabel = monthFormatter.string(from: Date()).uppercased()
        let today = Calendar.current.component(.day, from: Date())

        var events: [WidgetEvent] = []
        if let eventsJson = defaults?.string(forKey: "events_json"),
           let data = eventsJson.data(using: .utf8) {
            events = (try? JSONDecoder().decode([WidgetEvent].self, from: data)) ?? []
        }

        var weather: [WidgetWeather] = []
        if let weatherJson = defaults?.string(forKey: "weather_json"),
           let data = weatherJson.data(using: .utf8) {
            weather = (try? JSONDecoder().decode([WidgetWeather].self, from: data)) ?? []
        }

        return CalendarEntry(
            date: Date(),
            monthLabel: monthLabel,
            todayDay: today,
            events: events,
            weather: weather
        )
    }
}

// MARK: - Widget Configuration

@main
struct CalendarWidgetExtension: Widget {
    let kind = "CalendarWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CalendarTimelineProvider()) { entry in
            CalendarWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Calendar")
        .description("Shows your events and upcoming weather.")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}
