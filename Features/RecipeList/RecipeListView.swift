//
//  RecipeListView.swift
//  TasteLog
//
//  Created by Fukushima Haruka on 2026/03/05.
//

import SwiftUI
import SwiftData

struct RecipeListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Recipe.createdAt, order: .reverse) private var recipes: [Recipe]

    @State private var selectedWeight: Weight? = nil
    @State private var searchText = ""
    @State private var showRegistration = false

    var filtered: [Recipe] {
        recipes.filter { recipe in
            let matchWeight = selectedWeight == nil || recipe.weight == selectedWeight?.rawValue
            let matchSearch = searchText.isEmpty || recipe.name.contains(searchText)
            return matchWeight && matchSearch
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {

                // フィルターチップ
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ChipButton(label: "すべて", isSelected: selectedWeight == nil) {
                            selectedWeight = nil
                        }
                        ForEach(Weight.allCases) { w in
                            ChipButton(label: "\(w.emoji) \(w.rawValue)", isSelected: selectedWeight == w) {
                                selectedWeight = w
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                }

                Divider()

                if filtered.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "fork.knife")
                            .font(.system(size: 48))
                            .foregroundStyle(.secondary)
                        Text("レシピがありません")
                            .font(.system(size: 15))
                            .foregroundStyle(.secondary)
                        Button {
                            showRegistration = true
                        } label: {
                            Text("最初のレシピを登録する")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(Color.primary)
                                .clipShape(Capsule())
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVGrid(
                            columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
                            spacing: 12
                        ) {
                            ForEach(filtered) { recipe in
                                NavigationLink {
                                    RecipeDetailView(recipe: recipe, mood: .okay)
                                } label: {
                                    RecipeGridCard(recipe: recipe)
                                }
                                .buttonStyle(.plain)
                                .contextMenu {
                                    Button(role: .destructive) {
                                        deleteRecipe(recipe)
                                    } label: {
                                        Label("削除", systemImage: "trash")
                                    }
                                }
                            }
                        }
                        .padding(16)
                    }
                }
            }
            .navigationTitle("レシピ")
            .searchable(text: $searchText, prompt: "料理名で検索")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showRegistration = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 28, height: 28)
                            .background(Color.primary)
                            .clipShape(Circle())
                    }
                }
            }
            .sheet(isPresented: $showRegistration) {
                RegistrationMethodView()
            }
        }
    }

    private func deleteRecipe(_ recipe: Recipe) {
        let repo = RecipeRepository(context: modelContext)
        try? repo.delete(recipe)
    }
}

// MARK: - RecipeGridCard
struct RecipeGridCard: View {
    let recipe: Recipe

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 写真
            RoundedRectangle(cornerRadius: 0)
                .fill(Color(.systemGray5))
                .frame(height: 110)
                .overlay {
                    if let urlString = recipe.dishImageURL ?? recipe.recipeImageURL,
                       let url = URL(string: urlString) {
                        AsyncImage(url: url) { image in
                            image.resizable().scaledToFill()
                        } placeholder: {
                            ProgressView()
                        }
                    } else {
                        Image(systemName: "photo")
                            .foregroundStyle(.secondary)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(recipe.name)
                    .font(.system(size: 13, weight: .semibold))
                    .lineLimit(2)
                HStack(spacing: 4) {
                    Text(recipe.weightEnum.rawValue)
                    Text("·")
                    Text("\(recipe.cookingTime)分")
                }
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
            }
            .padding(10)
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.07), radius: 6, x: 0, y: 2)
    }
}
