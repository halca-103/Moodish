import SwiftUI
import SwiftData

struct SuggestionView: View {
    let mood: Mood
    let weight: Weight
    let ingredients: [String]

    @Environment(HealthKitService.self) private var healthKit
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Recipe.createdAt, order: .reverse) private var allRecipes: [Recipe]
    @Query(sort: \CookingLog.cookedAt, order: .reverse) private var allLogs: [CookingLog]

    @State private var navigateToDetail = false
    @State private var selectedRecipe: Recipe? = nil
    @State private var latestSleepFromHealth: Double? = nil
    private let recentAvoidDays = 7

    private var latestSleepHours: Double? {
        latestSleepFromHealth ?? allLogs.first(where: { $0.sleepHours != nil })?.sleepHours
    }

    private var sleepInsightText: String {
        guard let sleep = latestSleepHours else {
            switch healthKit.authorizationState {
            case .authorized:
                return "ヘルスケア連携中です。睡眠データ取得後に提案へ反映します"
            case .notAvailable:
                return "このデバイスではヘルスケア連携を利用できません"
            default:
                return "睡眠データ連携で、体調に合わせた提案ができます"
            }
        }
        if sleep < 6 {
            return "睡眠 \(String(format: "%.1f", sleep))h。今日は時短・負担少なめを優先"
        } else if sleep >= 7.5 {
            return "睡眠 \(String(format: "%.1f", sleep))h。しっかり作るメニューもおすすめ"
        } else {
            return "睡眠 \(String(format: "%.1f", sleep))h。バランス重視で提案中"
        }
    }

    private var sleepInlineText: String {
        if let sleep = latestSleepHours {
            return "\(String(format: "%.1f", sleep))h"
        }
        return "--h"
    }

    private var recentWeekDates: [Date] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return (0..<recentAvoidDays).compactMap {
            calendar.date(byAdding: .day, value: -$0, to: today)
        }.reversed()
    }

    private func isRecentlyCooked(_ recipe: Recipe) -> Bool {
        guard let latest = allLogs.first(where: { $0.recipe?.id == recipe.id })?.cookedAt else {
            return false
        }
        guard let threshold = Calendar.current.date(byAdding: .day, value: -(recentAvoidDays - 1), to: Date()) else {
            return false
        }
        return latest >= threshold
    }

    private var logsByDay: [Date: [CookingLog]] {
        let calendar = Calendar.current
        return Dictionary(grouping: allLogs) { log in
            calendar.startOfDay(for: log.cookedAt)
        }
    }

    private var suggestionItems: [SuggestionItem] {
        let weightValue = weight.rawValue
        var filtered = allRecipes.filter { $0.weight == weightValue }

        // 食材フィルタ
        if !ingredients.isEmpty {
            filtered = filtered.filter { recipe in
                ingredients.allSatisfy { ing in
                    recipe.ingredients.contains { $0.contains(ing) }
                }
            }
            // 一致がなければ全件に戻す
            if filtered.isEmpty { filtered = allRecipes }
        }

        // スコアリング：同じ気分で作った回数 + 睡眠時間との相性
        let moodValue = mood.rawValue
        let scored = filtered.map { recipe -> SuggestionItem in
            let moodScore = allLogs.filter {
                $0.recipe?.id == recipe.id && $0.mood == moodValue
            }.count
            let sleepFit: Int
            var reasons: [String] = []

            if moodScore > 0 {
                reasons.append("同じ気分で\(moodScore)回作成")
            }

            if let sleep = latestSleepHours {
                if sleep < 6 {
                    sleepFit = max(0, 30 - recipe.cookingTime) // 低睡眠時は短時間メニューを優先
                    if sleepFit > 0 {
                        reasons.append("睡眠\(String(format: "%.1f", sleep))hで時短優先")
                    }
                } else if sleep >= 7.5 {
                    sleepFit = min(6, recipe.cookingTime / 5) // 余裕がある日はやや時間のかかる料理も許容
                    if sleepFit > 0 {
                        reasons.append("睡眠\(String(format: "%.1f", sleep))hで調理余力あり")
                    }
                } else {
                    sleepFit = 0
                }
            } else {
                sleepFit = 0
            }
            let isRecent = isRecentlyCooked(recipe)
            let recentPenalty = isRecent ? -1000 : 0
            if isRecent {
                reasons.append("先週作ったので優先度を調整")
            }

            if reasons.isEmpty {
                reasons.append("最近の記録からバランス提案")
            }

            return SuggestionItem(
                recipe: recipe,
                score: moodScore * 10 + sleepFit + recentPenalty,
                reasons: reasons
            )
        }
        return scored.sorted { $0.score > $1.score }
    }

    var suggestions: [Recipe] {
        suggestionItems.map { $0.recipe }
    }

    var body: some View {
        VStack(spacing: 0) {
            // グラデーションヘッダー
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(mood.emoji)
                    Text("×").foregroundStyle(.white.opacity(0.7))
                    Text(weight.rawValue)
                    Text("×").foregroundStyle(.white.opacity(0.7))
                    Text(sleepInlineText)
                }
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white)

                if !ingredients.isEmpty {
                    Text(ingredients.joined(separator: "・"))
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.9))
                }

                Text("今日はこれにしよう")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.white)

                Label(sleepInsightText, systemImage: "bed.double.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.white.opacity(0.18))
                    .clipShape(Capsule())
                    .padding(.top, 6)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
            .background(AppTheme.gradientVertical)

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // 直近の調理カレンダー
                    VStack(alignment: .leading, spacing: 10) {
                        Text("最近の調理（7日）")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.secondary)
                        ScrollView(.horizontal, showsIndicators: false) {
                            LazyHStack(spacing: 10) {
                                ForEach(recentWeekDates, id: \.self) { date in
                                    DayCookCard(date: date, logs: logsByDay[date] ?? [])
                                }
                            }
                            .padding(.vertical, 2)
                            .padding(.horizontal, 2)
                        }
                        .contentShape(Rectangle())
                        Text("先週作ったレシピは、提案の優先度を下げています")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    }

                    if suggestions.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "fork.knife")
                                .font(.system(size: 48))
                                .foregroundStyle(.secondary)
                            Text("まだレシピが登録されていません")
                                .font(.system(size: 15))
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 80)
                    } else {
                        if let mainItem = suggestionItems.first {
                            Button {
                                selectedRecipe = mainItem.recipe
                                navigateToDetail = true
                            } label: {
                                RecipeMainCard(recipe: mainItem.recipe, reasons: mainItem.reasons)
                            }
                            .buttonStyle(.plain)
                        }

                        if suggestionItems.count > 1 {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("他の候補")
                                    .font(.system(size: 13))
                                    .foregroundStyle(.secondary)
                                ForEach(Array(suggestionItems.dropFirst().prefix(2))) { item in
                                    Button {
                                        selectedRecipe = item.recipe
                                        navigateToDetail = true
                                    } label: {
                                        RecipeRowCard(recipe: item.recipe, reasons: item.reasons)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                }
                .padding(20)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $navigateToDetail) {
            if let recipe = selectedRecipe {
                RecipeDetailView(recipe: recipe, mood: mood)
            }
        }
        .task {
            healthKit.refreshAuthorizationStatus()
            latestSleepFromHealth = await healthKit.fetchSleepHours()
        }
    }
}

private struct SuggestionItem: Identifiable {
    let recipe: Recipe
    let score: Int
    let reasons: [String]
    var id: UUID { recipe.id }
}

private struct DayCookCard: View {
    let date: Date
    let logs: [CookingLog]

    private var dayLabel: String {
        date.formatted(.dateTime.day())
    }

    private var weekLabel: String {
        date.formatted(.dateTime.weekday(.abbreviated))
    }

    private var titleText: String {
        let recipes = logs.compactMap { $0.recipe?.name }
        if recipes.isEmpty { return "作ってない" }
        if recipes.count == 1 { return recipes[0] }
        return "\(recipes[0]) 他\(recipes.count - 1)品"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(weekLabel)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.secondary)
            Text(dayLabel)
                .font(.system(size: 16, weight: .bold))
            Text(titleText)
                .font(.system(size: 11))
                .lineLimit(2)
                .foregroundStyle(logs.isEmpty ? .secondary : .primary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(10)
        .frame(width: 110, height: 90, alignment: .topLeading)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - RecipeMainCard
struct RecipeMainCard: View {
    let recipe: Recipe
    let reasons: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 写真
            RoundedRectangle(cornerRadius: 0)
                .fill(Color(.systemGray5))
                .frame(height: 160)
                .overlay {
                    if let urlString = recipe.dishImageURL ?? recipe.recipeImageURL,
                       let url = URL(string: urlString) {
                        AsyncImage(url: url) { image in
                            image.resizable().scaledToFill()
                        } placeholder: { ProgressView() }
                    } else {
                        Image(systemName: "photo")
                            .font(.system(size: 32))
                            .foregroundStyle(.secondary)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 8) {
                Text(recipe.name)
                    .font(.system(size: 17, weight: .bold))
                HStack(spacing: 8) {
                    Label(recipe.weightEnum.rawValue, systemImage: "scalemass")
                        .font(.system(size: 12))
                    Label("\(recipe.cookingTime)分", systemImage: "clock")
                        .font(.system(size: 12))
                }
                .foregroundStyle(.secondary)

                SuggestionReasonsView(reasons: reasons)
            }
            .padding(12)
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
    }
}

// MARK: - RecipeRowCard
struct RecipeRowCard: View {
    let recipe: Recipe
    let reasons: [String]

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemGray5))
                .frame(width: 56, height: 56)
                .overlay {
                    if let urlString = recipe.dishImageURL ?? recipe.recipeImageURL,
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

            VStack(alignment: .leading, spacing: 4) {
                Text(recipe.name)
                    .font(.system(size: 14, weight: .semibold))
                HStack(spacing: 6) {
                    Text(recipe.weightEnum.rawValue)
                    Text("·")
                    Text("\(recipe.cookingTime)分")
                }
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                SuggestionReasonsView(reasons: reasons)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 12))
                .foregroundStyle(.tertiary)
        }
        .padding(12)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 1)
    }
}

private struct SuggestionReasonsView: View {
    let reasons: [String]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(Array(reasons.prefix(2)), id: \.self) { reason in
                    Text(reason)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(AppTheme.accent)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(AppTheme.accentBg)
                        .clipShape(Capsule())
                }
            }
            .padding(.top, 2)
        }
    }
}
