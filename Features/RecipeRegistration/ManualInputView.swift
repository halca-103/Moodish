//
//  ManualInputView.swift
//  TasteLog
//
//  Created by Fukushima Haruka on 2026/03/04.
//

import SwiftUI
import SwiftData

struct ManualInputView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var cookingTime: Int = 15
    @State private var weight: Weight = .normal
    @State private var ingredients: [String] = [""]
    @State private var steps: [String] = [""]
    
    var onComplete: (() -> Void)? = nil

    var isValid: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        List {
            // 料理名
            Section("料理名") {
                TextField("例：鶏むね塩レモン蒸し", text: $name)
            }

            // 調理時間（ドラムピッカー）
            Section("調理時間") {
                Picker("調理時間", selection: $cookingTime) {
                    ForEach(Array(stride(from: 5, through: 180, by: 5)), id: \.self) { min in
                        Text("\(min) 分").tag(min)
                    }
                }
                .pickerStyle(.wheel)
                .frame(height: 120)
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

            // 材料
            Section("材料") {
                ForEach(ingredients.indices, id: \.self) { i in
                    HStack {
                        TextField("例：鶏むね肉 300g", text: $ingredients[i])
                        if ingredients.count > 1 {
                            Button {
                                ingredients.remove(at: i)
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .onMove { from, to in
                    ingredients.move(fromOffsets: from, toOffset: to)
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
                        TextField("手順を入力", text: $steps[i], axis: .vertical)
                            .lineLimit(2...5)
                        if steps.count > 1 {
                            Button {
                                steps.remove(at: i)
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .onMove { from, to in
                    steps.move(fromOffsets: from, toOffset: to)
                }
                Button {
                    steps.append("")
                } label: {
                    Label("手順を追加", systemImage: "plus")
                }
            }
        }
        .navigationTitle("レシピを入力")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            // 登録ボタンをNavBar右上に固定（キーボード出ても見える）
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("登録") {
                    saveRecipe()
                }
                .bold()
                .disabled(!isValid)
            }
            // 並び替えモード
            ToolbarItem(placement: .navigationBarLeading) {
                EditButton()
            }
        }
    }

//    private func saveRecipe() {
//        let recipe = Recipe(
//            name: name.trimmingCharacters(in: .whitespaces),
//            cookingTime: cookingTime,
//            weight: weight,
//            ingredients: ingredients.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty },
//            steps: steps.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
//        )
//        let repository = RecipeRepository(context: modelContext)
//        try? repository.save(recipe)
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
        onComplete?()
        dismiss()
    }
}

#Preview {
    NavigationStack {
        ManualInputView()
    }
}
