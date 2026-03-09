//
//  CookingLogView.swift
//  TasteLog
//
//  Created by Fukushima Haruka on 2026/03/05.
//

import SwiftUI
import SwiftData
import UIKit

struct CookingLogView: View {
    let recipe: Recipe
    let mood: Mood

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \CookingLog.cookedAt, order: .reverse) private var allLogs: [CookingLog]
    private let gemini = GeminiService()
    @Environment(\.dismiss) private var dismiss
    @AppStorage("selectedTab") private var selectedTab = 0
    @AppStorage("recipeTabResetID") private var recipeTabResetID = 0
    @State private var healthKit = HealthKitService()
    @State private var rating = 0
    @State private var memo = ""
    @State private var showSavedScreen = false
    @State private var aiSuggestion: String? = nil
    @State private var isGeneratingSuggestion = false
    @State private var lastLearningSummaries: [String] = []
    
    private var nextSuggestion: String? {
        MemoSuggestionService.suggestion(for: recipe, logs: allLogs)
    }

    private var suggestionText: String? {
        aiSuggestion ?? nextSuggestion
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {

                // レシピ名
                VStack(alignment: .leading, spacing: 4) {
                    Text(recipe.name)
                        .font(.system(size: 20, weight: .bold))
                    Text("今日の料理はどうでしたか？")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                }

                // 星評価
                VStack(alignment: .leading, spacing: 12) {
                    Text("評価")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.secondary)
                    HStack(spacing: 12) {
                        ForEach(1...5, id: \.self) { star in
                            Button {
                                rating = star
                            } label: {
                                Image(systemName: star <= rating ? "star.fill" : "star")
                                    .font(.system(size: 32))
                                    .foregroundStyle(star <= rating ? .yellow : Color(.systemGray4))
                            }
                            .buttonStyle(.plain)
                            .animation(.easeInOut(duration: 0.1), value: rating)
                        }
                    }
                }

                // メモ
                VStack(alignment: .leading, spacing: 12) {
                    Text("メモ")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.secondary)
                    TextField("感想・次回への改善点など", text: $memo, axis: .vertical)
                        .lineLimit(4...8)
                        .padding(14)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                if isGeneratingSuggestion && suggestionText == nil {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("次はこうしませんか？")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.secondary)
                        HStack(spacing: 8) {
                            ProgressView()
                                .scaleEffect(0.9)
                            Text("提案を作成中...")
                                .font(.system(size: 13))
                                .foregroundStyle(.secondary)
                        }
                        .padding(12)
                        .background(AppTheme.accentBg)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                } else if let suggestionText {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("次はこうしませんか？")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.secondary)
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "lightbulb.fill")
                                .foregroundStyle(AppTheme.accent)
                            Text(suggestionText)
                                .font(.system(size: 14))
                                .lineSpacing(3)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(12)
                        .background(AppTheme.accentBg)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
            .padding(20)
        }
        .navigationTitle("どうでしたか？")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("保存") {
                    Task { await saveLog() }
                }
                .bold()
                .disabled(rating == 0)
            }
        }
        .fullScreenCover(isPresented: $showSavedScreen) {
            LogSavedView(summaries: lastLearningSummaries) {
                navigateToRecipeList()
            }
        }
        .task(id: allLogs.count) {
            await generateSuggestion()
        }
    }

    private func saveLog() async {
        let (sleepHours,     _) = await healthKit.fetchTodayData()

        let log = CookingLog(
            mood: mood,
            rating: rating,
            memo: memo,
            sleepHours: sleepHours,
            stepCount: nil,
            recipe: recipe
        )
        let repo = LogRepository(context: modelContext)
        try? repo.save(log)
        lastLearningSummaries = buildLearningSummaries(sleepHours: sleepHours)

        await MainActor.run {
            showSavedScreen = true
        }
    }

    private func navigateToRecipeList() {
        recipeTabResetID += 1
        selectedTab = 1

        // 表示中の画面を閉じてレシピ一覧ルートへ戻す
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else { return }

        if let tabVC = findTabBarController(in: window.rootViewController) {
            tabVC.selectedIndex = 1
        }
        window.rootViewController?.dismiss(animated: true)
    }

    private func findTabBarController(in vc: UIViewController?) -> UITabBarController? {
        if let tab = vc as? UITabBarController { return tab }
        for child in vc?.children ?? [] {
            if let found = findTabBarController(in: child) { return found }
        }
        return nil
    }

    @MainActor
    private func generateSuggestion() async {
        let memos = allLogs
            .filter { $0.recipe?.id == recipe.id }
            .map { $0.memo.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .prefix(3)
            .map { $0 }

        guard !memos.isEmpty else {
            aiSuggestion = nil
            isGeneratingSuggestion = false
            return
        }

        isGeneratingSuggestion = true
        defer { isGeneratingSuggestion = false }
        do {
            aiSuggestion = try await gemini.generateMemoBasedSuggestion(
                recipeName: recipe.name,
                ingredients: recipe.ingredients,
                steps: recipe.steps,
                recentMemos: memos
            )
        } catch {
            aiSuggestion = nil
        }
    }

    private func buildLearningSummaries(sleepHours: Double?) -> [String] {
        var messages: [String] = []
        messages.append("「\(recipe.name)」の記録を学習に反映しました")

        if rating >= 4 {
            messages.append("高評価（★\(rating)）として次回候補の優先度を上げます")
        } else if rating > 0 {
            messages.append("評価（★\(rating)）を反映し、提案の並び順を調整します")
        }

        let trimmedMemo = memo.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedMemo.isEmpty {
            messages.append("メモ内容を次回の「改善提案」に反映します")
        }

        if let sleepHours {
            messages.append("睡眠\(String(format: "%.1f", sleepHours))hを次回提案に反映します")
        }

        return Array(messages.prefix(3))
    }
}

private struct LogSavedView: View {
    let summaries: [String]
    let onComplete: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "sparkles")
                .font(.system(size: 44, weight: .bold))
                .foregroundStyle(AppTheme.accent)

            Text("登録できました")
                .font(.system(size: 24, weight: .bold))

            Text("今日もレシピが少し育ちました")
                .font(.system(size: 15))
                .foregroundStyle(.secondary)

            if !summaries.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("今回の反映")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.secondary)
                    ForEach(summaries, id: \.self) { summary in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 12))
                                .foregroundStyle(AppTheme.accent)
                            Text(summary)
                                .font(.system(size: 13))
                                .foregroundStyle(.primary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
                .padding(12)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, 24)
            }

            Spacer()

            Button {
                onComplete()
            } label: {
                AppTheme.gradientButton(label: "レシピ一覧へ")
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .padding(.top, 24)
        .background(Color(.systemBackground))
    }
}
