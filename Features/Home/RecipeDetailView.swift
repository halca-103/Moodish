//
//  RecipeDetailView.swift
//  TasteLog
//
//  Created by Fukushima Haruka on 2026/03/05.
//
//import SwiftUI
//
//struct RecipeDetailView: View {
//    let recipe: Recipe
//    let mood: Mood
//
//    var body: some View {
//        Text("レシピ詳細（実装中）")
//            .navigationTitle(recipe.name)
//    }
//}



import SwiftUI

struct RecipeDetailView: View {
    let recipe: Recipe
    let mood: Mood

    @State private var navigateToTimer = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {

                // 写真
                RoundedRectangle(cornerRadius: 0)
                    .fill(Color(.systemGray5))
                    .frame(height: 220)
                    .overlay {
                        if let urlString = recipe.dishImageURL ?? recipe.recipeImageURL,
                           let url = URL(string: urlString) {
                            AsyncImage(url: url) { image in
                                image.resizable().scaledToFill()
                            } placeholder: { ProgressView() }
                        } else {
                            Image(systemName: "photo")
                                .font(.system(size: 40))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .clipped()

                VStack(alignment: .leading, spacing: 20) {

                    // タイトル + タグ
                    VStack(alignment: .leading, spacing: 8) {
                        Text(recipe.name)
                            .font(.system(size: 22, weight: .bold))

                        HStack(spacing: 8) {
                            TagView(label: recipe.weightEnum.rawValue, systemImage: "scalemass")
                            TagView(label: "\(recipe.cookingTime)分", systemImage: "clock")
                        }
                    }

                    Divider()

                    // 材料
                    VStack(alignment: .leading, spacing: 10) {
                        Text("材料")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.secondary)
                        ForEach(recipe.ingredients, id: \.self) { ing in
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(Color.primary)
                                    .frame(width: 5, height: 5)
                                Text(ing)
                                    .font(.system(size: 15))
                            }
                        }
                    }

                    Divider()

                    // 手順
                    VStack(alignment: .leading, spacing: 12) {
                        Text("手順")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.secondary)
                        ForEach(recipe.steps.indices, id: \.self) { i in
                            HStack(alignment: .top, spacing: 12) {
                                Text("\(i + 1)")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(.white)
                                    .frame(width: 22, height: 22)
                                    .background(Color.primary)
                                    .clipShape(Circle())
                                Text(recipe.steps[i])
                                    .font(.system(size: 15))
                                    .lineSpacing(4)
                            }
                        }
                    }

                    // これを作る！ボタン
                    Button {
                        navigateToTimer = true
                    } label: {
                        Text("これを作る！")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.primary)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .padding(.top, 8)
                }
                .padding(20)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $navigateToTimer) {
            TimerView(recipe: recipe, mood: mood)
        }
    }
}

// MARK: - TagView
struct TagView: View {
    let label: String
    let systemImage: String

    var body: some View {
        Label(label, systemImage: systemImage)
            .font(.system(size: 12, weight: .medium))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color(.systemGray6))
            .clipShape(Capsule())
    }
}
