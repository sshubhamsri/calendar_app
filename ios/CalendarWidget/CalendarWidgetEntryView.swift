import SwiftUI
import WidgetKit

// MARK: - Colors
private extension Color {
    static let background = Color(red: 0.0, green: 0.0, blue: 0.0)      // True black for OLED
    static let surface = Color(red: 0.051, green: 0.051, blue: 0.051)
    static let textPrimary = Color.white
    static let textSecondary = Color(red: 0.667, green: 0.667, blue: 0.667)
    static let textMuted = Color(red: 0.333, green: 0.333, blue: 0.333)
    static let sundayRed = Color(red: 0.906, green: 0.298, blue: 0.235)
    static let accent = Color(red: 0.290, green: 0.565, blue: 0.851)
    static let weekNumber = Color(red: 0.267, green: 0.267, blue: 0.267)
    static let divider = Color(red: 0.133, green: 0.133, blue: 0.133)
}

// MARK: - Entry View

struct CalendarWidgetEntryView: View {
    let entry: CalendarEntry

    private let calendar = Calendar.current
    private let dayLabels = ["M", "T", "W", "T", "F", "S", "S"]

    var body: some View {
        VStack(spacing: 4) {
            headerRow
            dayHeaderRow
            calendarGrid
        }
        .padding(10)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .widgetBackground(Color.background)
    }

    // MARK: Header

    private var headerRow: some View {
        HStack {
            Text(entry.monthLabel)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.textPrimary)
                .kerning(1.5)
            Spacer()
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.textPrimary, lineWidth: 1.5)
                    .frame(width: 30, height: 30)
                Text("\(entry.todayDay)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.textPrimary)
            }
        }
    }

    // MARK: Day Headers

    private var dayHeaderRow: some View {
        HStack(spacing: 0) {
            ForEach(dayLabels.indices, id: \.self) { i in
                Text(dayLabels[i])
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(i == 6 ? .sundayRed : .textSecondary)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: Calendar Grid

    private var calendarGrid: some View {
        let days = monthGridDays()
        let rows = days.chunked(into: 7)

        return VStack(spacing: 0) {
            ForEach(rows.indices, id: \.self) { rowIdx in
                HStack(spacing: 0) {
                    ForEach(rows[rowIdx].indices, id: \.self) { colIdx in
                        let date = rows[rowIdx][colIdx]
                        dayCellView(for: date)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private func dayCellView(for date: Date) -> some View {
        let day = calendar.component(.day, from: date)
        let isToday = calendar.isDateInToday(date)
        let isSunday = calendar.component(.weekday, from: date) == 1
        let isCurrentMonth = calendar.component(.month, from: date) ==
            calendar.component(.month, from: entry.date)
        let eventsForDay = events(on: date)
        let weather = weatherFor(date: date)

        VStack(spacing: 1) {
            // Day number
            HStack(spacing: 2) {
                ZStack {
                    if isToday {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 20, height: 20)
                    }
                    Text("\(day)")
                        .font(.system(size: 10, weight: isToday ? .bold : .regular))
                        .foregroundColor(
                            isToday ? Color.background :
                            !isCurrentMonth ? .textMuted :
                            isSunday ? .sundayRed : .textPrimary
                        )
                }
                Spacer()
                if let w = weather, isCurrentMonth {
                    Text(weatherEmoji(for: w.iconCode))
                        .font(.system(size: 8))
                }
            }
            .padding(.horizontal, 2)

            // Event dots
            if isCurrentMonth && !eventsForDay.isEmpty {
                HStack(spacing: 2) {
                    ForEach(eventsForDay.prefix(3)) { event in
                        Circle()
                            .fill(event.swiftColor)
                            .frame(width: 4, height: 4)
                    }
                    Spacer()
                }
                .padding(.horizontal, 3)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(
            Rectangle()
                .fill(Color.divider)
                .frame(height: 0.5),
            alignment: .top
        )
    }

    // MARK: Helpers

    private func monthGridDays() -> [Date] {
        let now = entry.date
        var comps = calendar.dateComponents([.year, .month], from: now)
        comps.day = 1
        guard let firstOfMonth = calendar.date(from: comps) else { return [] }

        let firstWeekday = calendar.component(.weekday, from: firstOfMonth)
        // Monday-based: Mon=2 → offset 1, Sun=1 → offset 6
        let offset = (firstWeekday + 5) % 7
        guard let gridStart = calendar.date(byAdding: .day, value: -offset, to: firstOfMonth)
        else { return [] }

        let lastOfMonth = calendar.date(
            byAdding: DateComponents(month: 1, day: -1), to: firstOfMonth
        ) ?? firstOfMonth
        let lastWeekday = calendar.component(.weekday, from: lastOfMonth)
        let trailing = (8 - lastWeekday) % 7
        let total = offset + calendar.component(.day, from: lastOfMonth) + trailing

        return (0..<total).compactMap {
            calendar.date(byAdding: .day, value: $0, to: gridStart)
        }
    }

    private func events(on date: Date) -> [WidgetEvent] {
        let key = dateKey(date)
        return entry.events.filter { event in
            guard let start = event.startDate else { return false }
            return dateKey(start) == key && !event.isHoliday
        }
    }

    private func weatherFor(date: Date) -> WidgetWeather? {
        let key = dateKey(date)
        return entry.weather.first { dateKey(fromIso: $0.date) == key }
    }

    private func dateKey(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }

    private func dateKey(fromIso iso: String) -> String {
        return String(iso.prefix(10))
    }

    private func weatherEmoji(for code: String) -> String {
        switch true {
        case code.hasPrefix("01"): return "☀️"
        case code.hasPrefix("02"): return "🌤"
        case code.hasPrefix("03"), code.hasPrefix("04"): return "☁️"
        case code.hasPrefix("09"), code.hasPrefix("10"): return "🌧"
        case code.hasPrefix("11"): return "⛈"
        case code.hasPrefix("13"): return "❄️"
        case code.hasPrefix("50"): return "🌫"
        default: return "🌡"
        }
    }
}

// MARK: - Array chunked helper

private extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}

// MARK: - Cross-version widget background

private extension View {
    @ViewBuilder
    func widgetBackground(_ color: Color) -> some View {
        if #available(iOS 17, *) {
            self.containerBackground(color, for: .widget)
        } else {
            self.background(color)
        }
    }
}
