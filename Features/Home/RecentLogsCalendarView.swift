import SwiftUI
import SwiftData

struct RecentLogsCalendarView: View {
    @Query(sort: \CookingLog.cookedAt, order: .reverse) private var logs: [CookingLog]
    @State private var displayMonth: Date = Date()
    @State private var selectedDate: Date = Date()

    private var calendar: Calendar { Calendar.current }

    private var logsByDay: [Date: [CookingLog]] {
        Dictionary(grouping: logs) { log in
            calendar.startOfDay(for: log.cookedAt)
        }
    }

    private var monthTitle: String {
        displayMonth.formatted(.dateTime.year().month())
    }

    private var selectedDayLogs: [CookingLog] {
        logsByDay[calendar.startOfDay(for: selectedDate)] ?? []
    }

    private var daysInMonth: [Date] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: displayMonth) else { return [] }
        let start = monthInterval.start
        let dayCount = calendar.range(of: .day, in: .month, for: start)?.count ?? 0
        return (0..<dayCount).compactMap { calendar.date(byAdding: .day, value: $0, to: start) }
    }

    private var firstWeekdayOffset: Int {
        guard let first = daysInMonth.first else { return 0 }
        let weekday = calendar.component(.weekday, from: first) // 1:日曜
        return max(0, weekday - 1)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Button {
                        if let prev = calendar.date(byAdding: .month, value: -1, to: displayMonth) {
                            displayMonth = prev
                        }
                    } label: {
                        Image(systemName: "chevron.left")
                            .foregroundStyle(.primary)
                    }
                    Spacer()
                    Text(monthTitle)
                        .font(.system(size: 18, weight: .bold))
                    Spacer()
                    Button {
                        if let next = calendar.date(byAdding: .month, value: 1, to: displayMonth) {
                            displayMonth = next
                        }
                    } label: {
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.primary)
                    }
                }
                .padding(.horizontal, 4)

                let weekdays = ["日", "月", "火", "水", "木", "金", "土"]
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 7), spacing: 8) {
                    ForEach(weekdays, id: \.self) { day in
                        Text(day)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.secondary)
                    }

                    ForEach(0..<firstWeekdayOffset, id: \.self) { _ in
                        Color.clear.frame(height: 44)
                    }

                    ForEach(daysInMonth, id: \.self) { day in
                        DayCell(
                            day: day,
                            isSelected: calendar.isDate(day, inSameDayAs: selectedDate),
                            hasLog: logsByDay[calendar.startOfDay(for: day)] != nil
                        ) {
                            selectedDate = day
                        }
                    }
                }
                .padding(12)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 14))

                VStack(alignment: .leading, spacing: 10) {
                    Text(selectedDate.formatted(.dateTime.year().month().day()))
                        .font(.system(size: 15, weight: .semibold))

                    if selectedDayLogs.isEmpty {
                        Text("この日の記録はありません")
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                            .padding(.vertical, 6)
                    } else {
                        ForEach(selectedDayLogs) { log in
                            HStack(spacing: 10) {
                                Text(log.moodEnum.emoji)
                                    .font(.system(size: 16))
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(log.recipe?.name ?? "不明")
                                        .font(.system(size: 14, weight: .semibold))
                                    HStack(spacing: 6) {
                                        Text(log.cookedAt.formatted(.dateTime.hour().minute()))
                                        if log.rating > 0 {
                                            Text("★\(log.rating)")
                                        }
                                    }
                                    .font(.system(size: 12))
                                    .foregroundStyle(.secondary)
                                }
                                Spacer()
                            }
                            .padding(10)
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                    }
                }
            }
            .padding(20)
        }
        .navigationTitle("記録カレンダー")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if let latest = logs.first?.cookedAt {
                selectedDate = latest
                displayMonth = latest
            }
        }
    }
}

private struct DayCell: View {
    let day: Date
    let isSelected: Bool
    let hasLog: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                Text(day.formatted(.dateTime.day()))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(isSelected ? .white : .primary)
                Circle()
                    .fill(hasLog ? (isSelected ? Color.white : AppTheme.accent) : Color.clear)
                    .frame(width: 5, height: 5)
            }
            .frame(maxWidth: .infinity, minHeight: 44)
            .background(isSelected ? AppTheme.accent : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }
}
