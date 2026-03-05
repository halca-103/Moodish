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
    var onRegistered: (() -> Void)? = nil

    @State private var name: String
    @State private var cookingTime: Int
    @State private var weight: Weight
    @State private var ingredients: [String]
    @State private var steps: [String]

    init(result: RecipeAnalysisResult, image: UIImage, onRegistered: (() -> Void)? = nil) {
        self.result = result
        self.image = image
        self.onRegistered = onRegistered
        _name        = State(initialValue: result.name)
        _cookingTime = State(initialValue: result.cookingTime)
        _weight      = State(initialValue: Weight(rawValue: result.weight) ?? .normal)
        _ingredients = State(initialValue: result.ingredients)
        _steps       = State(initialValue: result.steps)
    }

    var body: some View {
        List {
            // 精度バッジ
            Section {
                Label("AIが読み取りました。タップして修正できます", systemImage: "checkmark.circle.fill")
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
                    TextField("材料", text: $ingredients[i])
                }
                Button {
                    ingredients.append("")
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
                    saveRecipe()
                }
                .bold()
                .disabled(name.isEmpty)
            }
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
//        // ルートまで戻る
//        dismiss()
//    }
    private func saveRecipe() {
        let recipe = Recipe(
            name: name,
            cookingTime: cookingTime,
            weight: weight,
            ingredients: ingredients.filter { !$0.isEmpty },
            steps: steps.filter { !$0.isEmpty }
        )
        let repository = RecipeRepository(context: modelContext)
        try? repository.save(recipe)
        onRegistered?()
        dismiss()
    }
}
