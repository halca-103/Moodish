import SwiftUI
import SwiftData

struct RecipeDetailView: View {
    let recipe: Recipe
    let mood: Mood
    @Query(sort: \CookingLog.cookedAt, order: .reverse) private var logs: [CookingLog]

    @State private var navigateToTimer = false
    @State private var navigateToEdit = false

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

                    if let source = recipe.sourceURL,
                       let sourceURL = URL(string: source) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("取得元")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(.secondary)
                            Link(destination: sourceURL) {
                                HStack(spacing: 8) {
                                    Image(systemName: "link")
                                        .font(.system(size: 13, weight: .semibold))
                                    Text(sourceURL.host ?? source)
                                        .font(.system(size: 14, weight: .semibold))
                                        .lineLimit(1)
                                    Spacer()
                                    Image(systemName: "arrow.up.right.square")
                                        .font(.system(size: 13))
                                }
                                .foregroundStyle(AppTheme.accent)
                                .padding(12)
                                .background(AppTheme.accentBg)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                        }
                    }

                    Divider()

                    // 該当レシピのログだけ絞り込む
                    let recipeLogs = logs.filter { $0.recipe?.id == recipe.id }
                    let ratedLogs = recipeLogs.filter { $0.rating > 0 }
                    let avgRating: Double? = ratedLogs.isEmpty ? nil
                        : Double(ratedLogs.map { $0.rating }.reduce(0, +)) / Double(ratedLogs.count)

                    // 一言メモ + 評価セクション
                    if !recipeLogs.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            // 平均評価
                            if let avg = avgRating {
                                HStack(spacing: 6) {
                                    ForEach(1...5, id: \.self) { star in
                                        Image(systemName: Double(star) <= avg ? "star.fill" : "star")
                                            .font(.system(size: 14))
                                            .foregroundStyle(Double(star) <= avg ? .yellow : Color(.systemGray4))
                                    }
                                    Text(String(format: "%.1f", avg))
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundStyle(.secondary)
                                    Text("（\(ratedLogs.count)回）")
                                        .font(.system(size: 12))
                                        .foregroundStyle(.secondary)
                                }
                            }

                            // 一言メモ
                            let memoLogs = recipeLogs.filter { !$0.memo.isEmpty }.prefix(3)
                            if !memoLogs.isEmpty {
                                Text("一言メモ")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(.secondary)

                                ForEach(Array(memoLogs), id: \.id) { log in
                                    HStack(alignment: .top, spacing: 8) {
                                        Text(log.moodEnum.emoji)
                                            .font(.system(size: 14))
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(log.memo)
                                                .font(.system(size: 14))
                                                .lineSpacing(3)
                                            HStack(spacing: 4) {
                                                ForEach(1...5, id: \.self) { star in
                                                    Image(systemName: star <= log.rating ? "star.fill" : "star")
                                                        .font(.system(size: 10))
                                                        .foregroundStyle(star <= log.rating ? .yellow : Color(.systemGray4))
                                                }
                                                Text(log.cookedAt.formatted(.dateTime.month().day()))
                                                    .font(.system(size: 11))
                                                    .foregroundStyle(.secondary)
                                            }
                                        }
                                    }
                                    .padding(12)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(AppTheme.accentBg)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                }
                            }
                        }

                        Divider()
                    }

                    // 材料
                    VStack(alignment: .leading, spacing: 10) {
                        Text("材料")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.secondary)
                        VStack(spacing: 0) {
                            ForEach(Array(recipe.ingredients.enumerated()), id: \.offset) { index, ing in
                                HStack(alignment: .top, spacing: 10) {
                                    Circle()
                                        .fill(AppTheme.accent)
                                        .frame(width: 6, height: 6)
                                        .padding(.top, 7)
                                    Text(ing)
                                        .font(.system(size: 16, weight: .medium))
                                        .lineSpacing(4)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 12)

                                if index < recipe.ingredients.count - 1 {
                                    Divider()
                                        .padding(.horizontal, 14)
                                }
                            }
                        }
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    Divider()

                    // 手順
                    VStack(alignment: .leading, spacing: 12) {
                        Text("手順")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.secondary)
                        ForEach(recipe.steps.indices, id: \.self) { i in
                            VStack(alignment: .leading, spacing: 8) {
                                HStack(spacing: 8) {
                                    Text("\(i + 1)")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundStyle(.white)
                                        .frame(width: 22, height: 22)
                                        .background(AppTheme.accent)
                                        .clipShape(Circle())
                                    Text("STEP \(i + 1)")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundStyle(.secondary)
                                }
                                Text(recipe.steps[i])
                                    .font(.system(size: 16))
                                    .lineSpacing(5)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .padding(14)
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }

                    // これを作る！ボタン
                    Button {
                        navigateToTimer = true
                    } label: {
                        Text("これを作る！ →")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(AppTheme.gradient)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .padding(.top, 8)
                }
                .padding(20)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("編集") {
                    navigateToEdit = true
                }
            }
        }
        .navigationDestination(isPresented: $navigateToTimer) {
            TimerView(recipe: recipe, mood: mood)
        }
        .navigationDestination(isPresented: $navigateToEdit) {
            RecipeEditView(recipe: recipe)
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
