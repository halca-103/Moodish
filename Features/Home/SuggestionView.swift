//
//  SuggestionView.swift
//  TasteLog
//
//  Created by Fukushima Haruka on 2026/03/05.
//
import SwiftUI
import SwiftData

struct SuggestionView: View {
    let mood: Mood
    let weight: Weight
    let ingredients: [String]

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Recipe.createdAt, order: .reverse) private var allRecipes: [Recipe]
    @Query(sort: \CookingLog.cookedAt, order: .reverse) private var allLogs: [CookingLog]

    @State private var navigateToDetail = false
    @State private var selectedRecipe: Recipe? = nil

    var suggestions: [Recipe] {
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

        // スコアリング：同じ気分で作った回数が多いほど上位
        let moodValue = mood.rawValue
        let scored = filtered.map { recipe -> (Recipe, Int) in
            let score = allLogs.filter {
                $0.recipe?.id == recipe.id && $0.mood == moodValue
            }.count
            return (recipe, score)
        }
        return scored.sorted { $0.1 > $1.1 }.map { $0.0 }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

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
                    // メイン提案
                    if let main = suggestions.first {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("今日はこれにしよう")
                                .font(.system(size: 17, weight: .bold))
                            Text("過去の記録から提案")
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)

                            Button {
                                selectedRecipe = main
                                navigateToDetail = true
                            } label: {
                                RecipeMainCard(recipe: main)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    // 他の候補
                    if suggestions.count > 1 {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("他の候補")
                                .font(.system(size: 13))
                                .foregroundStyle(.secondary)

                            ForEach(suggestions.dropFirst().prefix(2)) { recipe in
                                Button {
                                    selectedRecipe = recipe
                                    navigateToDetail = true
                                } label: {
                                    RecipeRowCard(recipe: recipe)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
            .padding(20)
        }
        .navigationTitle("\(mood.emoji) \(mood.rawValue) の提案")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $navigateToDetail) {
            if let recipe = selectedRecipe {
                RecipeDetailView(recipe: recipe, mood: mood)
            }
        }
    }
}

// MARK: - RecipeMainCard
struct RecipeMainCard: View {
    let recipe: Recipe

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
