import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \CookingLog.cookedAt, order: .reverse) private var recentLogs: [CookingLog]

    @State private var selectedMood: Mood? = nil
    @State private var navigateToFilter = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {

                    // TODAY'S MOOD
                    VStack(alignment: .leading, spacing: 12) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("TODAY'S MOOD")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(.secondary)
                                .kerning(1)
                            Text("ひとつ選んでください")
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 20)

                        LazyVGrid(
                            columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3),
                            spacing: 10
                        ) {
                            ForEach(Mood.allCases) { mood in
                                MoodCell(mood: mood, isSelected: selectedMood == mood) {
                                    withAnimation(.easeInOut(duration: 0.15)) {
                                        selectedMood = mood
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)

                        // 次へボタン
                        Button {
                            navigateToFilter = true
                        } label: {
                            HStack {
                                Text("→ 次へ")
                                    .font(.system(size: 16, weight: .bold))
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(
                                        selectedMood == nil
                                            ? AnyShapeStyle(Color(.systemGray4))
                                            : AnyShapeStyle(AppTheme.gradient)
                                    )
                            )
                            .animation(.easeInOut(duration: 0.2), value: selectedMood == nil)
                        }
                        .disabled(selectedMood == nil)
                        .padding(.horizontal, 20)
                    }
                    .padding(.vertical, 16)
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color(.systemGray5), lineWidth: 1)
                    )
                    .padding(.horizontal, 16)

                    // 最近の記録
                    if !recentLogs.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            NavigationLink {
                                RecentLogsCalendarView()
                            } label: {
                                HStack {
                                    Text("最近の記録")
                                        .font(.system(size: 15, weight: .semibold))
                                    Spacer()
                                    HStack(spacing: 6) {
                                        Text("カレンダーで見る")
                                            .font(.system(size: 12, weight: .semibold))
                                        Image(systemName: "calendar")
                                            .font(.system(size: 12, weight: .semibold))
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 11, weight: .semibold))
                                    }
                                    .foregroundStyle(AppTheme.accent)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(AppTheme.accentBg)
                                    .clipShape(Capsule())
                                }
                                .padding(.horizontal, 20)
                            }
                            .buttonStyle(.plain)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(recentLogs.prefix(5)) { log in
                                        RecentLogCard(log: log)
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                        }
                    }
                }
                .padding(.top, 16)
                .padding(.bottom, 40)
            }
            .background(Color(.systemGray6))
            .navigationTitle("今日何食べる？")
            .navigationBarTitleDisplayMode(.large)
            .navigationDestination(isPresented: $navigateToFilter) {
                if let mood = selectedMood {
                    FilterView(mood: mood)
                }
            }
        }
    }
}

// MARK: - MoodCell
struct MoodCell: View {
    let mood: Mood
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 6) {
                Text(mood.emoji)
                    .font(.system(size: 28))
                Text(mood.rawValue)
                    .font(.system(size: 11, weight: isSelected ? .bold : .regular))
                    .foregroundStyle(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? AnyShapeStyle(AppTheme.accentBg) : AnyShapeStyle(Color(.systemGray6)))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? AppTheme.accent : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - RecentLogCard
struct RecentLogCard: View {
    let log: CookingLog

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemGray5))
                .frame(width: 120, height: 80)
                .overlay {
                    if let urlString = log.recipe?.dishImageURL,
                       let url = URL(string: urlString) {
                        AsyncImage(url: url) { image in
                            image.resizable().scaledToFill()
                        } placeholder: { ProgressView() }
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    } else {
                        Image(systemName: "fork.knife")
                            .foregroundStyle(.secondary)
                    }
                }

            Text(log.recipe?.name ?? "不明")
                .font(.system(size: 11, weight: .semibold))
                .lineLimit(1)
                .frame(width: 120, alignment: .leading)

            HStack(spacing: 4) {
                Text(log.cookedAt.formatted(.dateTime.month().day()))
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                Text(log.moodEnum.emoji)
                    .font(.system(size: 10))
            }
        }
    }
}
