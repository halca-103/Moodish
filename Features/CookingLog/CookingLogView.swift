//
//  CookingLogView.swift
//  TasteLog
//
//  Created by Fukushima Haruka on 2026/03/05.
//

import SwiftUI
import SwiftData

struct CookingLogView: View {
    let recipe: Recipe
    let mood: Mood

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var rating = 0
    @State private var memo = ""

    // ルートまで全部戻るために使う
    @State private var navigateToRoot = false

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
            }
            .padding(20)
        }
        .navigationTitle("どうでしたか？")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("保存") {
                    saveLog()
                }
                .bold()
                .disabled(rating == 0)
            }
        }
    }

    private func saveLog() {
        let log = CookingLog(
            mood: mood,
            rating: rating,
            memo: memo,
            recipe: recipe
        )
        let repo = LogRepository(context: modelContext)
        try? repo.save(log)

        // NavigationStack のルートまで全部戻る
        // TabView のホームタブに戻る
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let tabBarController = window.rootViewController?.children.first as? UITabBarController
        else {
            dismiss()
            return
        }
        tabBarController.selectedIndex = 0
        window.rootViewController?.dismiss(animated: true)
        dismiss()
    }
}
