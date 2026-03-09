//
//  AnalysisResultView.swift
//  TasteLog
//
//  Created by Fukushima Haruka on 2026/03/05.
//

import SwiftUI
import SwiftData

struct AnalysisResultView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let result: RecipeAnalysisResult
    let image: UIImage
    let aiBadgeText: String
    var onRegistered: (() -> Void)? = nil
    var onComplete: (() -> Void)? = nil

    @State private var name: String
    @State private var cookingTime: Int
    @State private var weight: Weight
    @State private var ingredients: [IngredientInput]
    @State private var steps: [String]
    @State private var dishImage: UIImage? = nil
    @State private var isUploading = false
    @State private var showDishPicker = false
    private let storageService = StorageService()
    private var hasImportedImage: Bool { image.size.width > 0 && image.size.height > 0 }

    init(
        result: RecipeAnalysisResult,
        image: UIImage,
        aiBadgeText: String = "AI画像解析済み（精度確認用）",
        onRegistered: (() -> Void)? = nil
    ) {
        self.result = result
        self.image = image
        self.aiBadgeText = aiBadgeText
        self.onRegistered = onRegistered
        _name        = State(initialValue: result.name)
        _cookingTime = State(initialValue: result.cookingTime)
        _weight      = State(initialValue: Weight(rawValue: result.weight) ?? .normal)
        if result.ingredientDetails.isEmpty {
            _ingredients = State(initialValue: result.ingredients.map { IngredientInput(name: $0) })
        } else {
            _ingredients = State(initialValue: result.ingredientDetails.map {
                IngredientInput(name: $0.name, amount: $0.amount, unit: IngredientUnit(rawValue: $0.unit) ?? .none)
            })
        }
        _steps       = State(initialValue: result.steps)
    }

    var body: some View {
        List {
            Section("インポート画像") {
                if hasImportedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 180)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                } else if let recipeImageURL = result.recipeImageURL,
                          let url = URL(string: recipeImageURL) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                    }
                    .frame(height: 180)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                } else {
                    HStack(spacing: 8) {
                        Image(systemName: "photo")
                            .foregroundStyle(.secondary)
                        Text("インポート画像が見つかりませんでした")
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section("料理の写真") {
                if let dishImage {
                    Image(uiImage: dishImage)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 160)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .onTapGesture { showDishPicker = true }
                } else {
                    Button {
                        showDishPicker = true
                    } label: {
                        HStack {
                            Image(systemName: "camera")
                            Text("完成した料理の写真を追加")
                                .font(.system(size: 14))
                        }
                        .foregroundStyle(AppTheme.accent)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(AppTheme.accentBg)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)
                }
            }

            // 精度バッジ
            Section {
                Label(aiBadgeText, systemImage: "checkmark.circle.fill")
                    .font(.system(size: 13))
                    .foregroundStyle(.green)
            }

            // 料理名
            Section("料理名") {
                TextField("料理名", text: $name)
            }

            // 重さ
            Section("重さ") {
                Picker("重さ", selection: $weight) {
                    ForEach(Weight.allCases) { w in
                        Text("\(w.emoji) \(w.rawValue)").tag(w)
                    }
                }
                .pickerStyle(.segmented)
            }

            // 調理時間
            Section("調理時間") {
                Stepper("\(cookingTime) 分", value: $cookingTime, in: 5...180, step: 5)
            }

            // 材料
            Section("材料") {
                ForEach(ingredients.indices, id: \.self) { i in
                    VStack(alignment: .leading, spacing: 8) {
                        TextField("食材名", text: $ingredients[i].name)
                        HStack(spacing: 8) {
                            TextField("分量", text: $ingredients[i].amount)
                                .keyboardType(.decimalPad)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 8)
                                .background(Color(.systemGray6))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .frame(width: 110)

                            Picker("", selection: $ingredients[i].unit) {
                                ForEach(IngredientUnit.allCases) { unit in
                                    Text(unit.label).tag(unit)
                                }
                            }
                            .labelsHidden()
                            .pickerStyle(.menu)
                            .frame(width: 92)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 8)
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                }
                Button {
                    ingredients.append(IngredientInput())
                } label: {
                    Label("材料を追加", systemImage: "plus")
                }
            }

            // 手順
            Section("手順") {
                ForEach(steps.indices, id: \.self) { i in
                    HStack(alignment: .top, spacing: 10) {
                        Text("\(i + 1)")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 22, height: 22)
                            .background(.primary)
                            .clipShape(Circle())
                        TextField("手順", text: $steps[i], axis: .vertical)
                    }
                }
                Button {
                    steps.append("")
                } label: {
                    Label("手順を追加", systemImage: "plus")
                }
            }
        }
        .navigationTitle("読み取り結果を確認")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("登録") {
                    Task { await saveRecipe() }
                }
                .bold()
                .disabled(name.isEmpty || isUploading)
            }
        }
        .sheet(isPresented: $showDishPicker) {
            ImagePickerView(sourceType: .photoLibrary, selectedImage: $dishImage)
        }
    }


//    private func saveRecipe() {
//        let recipe = Recipe(
//            name: name,
//            cookingTime: cookingTime,
//            weight: weight,
//            ingredients: ingredients.filter { !$0.isEmpty },
//            steps: steps.filter { !$0.isEmpty }
//        )
//        let repository = RecipeRepository(context: modelContext)
//        try? repository.save(recipe)
//        if let onRegistered {
//            onRegistered()
//            return
//        }
//        dismiss()
//    }
    private func saveRecipe() async {
        isUploading = true
        let recipeId = UUID()

        var dishImageURL: String? = nil
        if let dishImage {
            do {
                dishImageURL = try await storageService.uploadDishImage(dishImage, recipeId: recipeId)
            } catch {
                print("料理写真アップロード失敗: \(error)")
            }
        }

        // URLインポート時は、追加写真がなくてもインポート画像を料理写真として使う
        let finalDishImageURL = dishImageURL ?? result.recipeImageURL

        let recipe = Recipe(
            id: recipeId,
            name: name,
            cookingTime: cookingTime,
            weight: weight,
            ingredients: ingredients.map { $0.formattedText }.filter { !$0.isEmpty },
            steps: steps.filter { !$0.isEmpty },
            recipeImageURL: result.recipeImageURL,
            dishImageURL: finalDishImageURL,
            sourceURL: result.sourceURL
        )
        let repository = RecipeRepository(context: modelContext)
        try? repository.save(recipe)

        onComplete?()
        isUploading = false
        dismissToRoot()
    }

    private func dismissToRoot() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let root = window.rootViewController else {
            dismiss()
            return
        }
        root.dismiss(animated: true)
    }
}

private struct IngredientInput: Identifiable {
    let id = UUID()
    var name: String = ""
    var amount: String = ""
    var unit: IngredientUnit = .none

    var formattedText: String {
        let n = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let a = amount.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !n.isEmpty else { return "" }
        guard !a.isEmpty else { return n }
        return unit == .none ? "\(n) \(a)" : "\(n) \(a)\(unit.rawValue)"
    }
}

private enum IngredientUnit: String, CaseIterable, Identifiable {
    case none = ""
    case g = "g"
    case kg = "kg"
    case ml = "ml"
    case l = "L"
    case tsp = "小さじ"
    case tbsp = "大さじ"
    case cup = "カップ"
    case piece = "個"
    case sheet = "枚"
    case pack = "パック"
    case pinch = "ひとつまみ"

    var id: String { rawValue }
    var label: String { rawValue.isEmpty ? "なし" : rawValue }
}
