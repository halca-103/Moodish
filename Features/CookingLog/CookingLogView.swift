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
    @Environment(\.dismiss) private var dismiss
    @AppStorage("selectedTab") private var selectedTab = 0
    @State private var healthKit = HealthKitService()
    @State private var rating = 0
    @State private var memo = ""
    @State private var showSavedScreen = false
    
    private var nextSuggestion: String? {
        MemoSuggestionService.suggestion(for: recipe, logs: allLogs)
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

                if let nextSuggestion {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("次はこうしませんか？")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.secondary)
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "lightbulb.fill")
                                .foregroundStyle(AppTheme.accent)
                            Text(nextSuggestion)
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
            LogSavedView {
                navigateToMoodSelection()
            }
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

        await MainActor.run {
            showSavedScreen = true
        }
    }

    private func navigateToMoodSelection() {
        // ホームタブ（index 0）に戻す
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else { return }

        // NavigationStack を全部popしてからタブを0に切り替え
        if let tabVC = findTabBarController(in: window.rootViewController) {
            tabVC.selectedIndex = 0
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
}

private struct LogSavedView: View {
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

            Spacer()

            Button {
                onComplete()
            } label: {
                AppTheme.gradientButton(label: "気分を選ぶ画面へ")
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .padding(.top, 24)
        .background(Color(.systemBackground))
    }
}
