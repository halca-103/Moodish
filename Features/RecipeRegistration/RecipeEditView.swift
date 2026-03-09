import SwiftUI
import SwiftData

struct RecipeEditView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var recipe: Recipe

    @State private var name: String
    @State private var cookingTime: Int
    @State private var weight: Weight
    @State private var ingredients: [IngredientInput]
    @State private var steps: [String]

    init(recipe: Recipe) {
        self.recipe = recipe
        _name = State(initialValue: recipe.name)
        _cookingTime = State(initialValue: recipe.cookingTime)
        _weight = State(initialValue: recipe.weightEnum)
        _ingredients = State(
            initialValue: recipe.ingredients.isEmpty
                ? [IngredientInput()]
                : recipe.ingredients.map { IngredientInput.parse(from: $0) }
        )
        _steps = State(initialValue: recipe.steps.isEmpty ? [""] : recipe.steps)
    }

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        List {
            Section("料理名") {
                TextField("料理名", text: $name)
            }

            Section("調理時間") {
                Picker("調理時間", selection: $cookingTime) {
                    ForEach(Array(stride(from: 5, through: 180, by: 5)), id: \.self) { min in
                        Text("\(min) 分").tag(min)
                    }
                }
                .pickerStyle(.wheel)
                .frame(height: 120)
            }

            Section("重さ") {
                Picker("重さ", selection: $weight) {
                    ForEach(Weight.allCases) { w in
                        Text("\(w.emoji) \(w.rawValue)").tag(w)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section("材料") {
                ForEach(ingredients.indices, id: \.self) { i in
                    VStack(alignment: .leading, spacing: 8) {
                        TextField("食材名（例：鶏もも肉）", text: $ingredients[i].name)
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
                }
                .onMove { from, to in
                    ingredients.move(fromOffsets: from, toOffset: to)
                }

                Button {
                    ingredients.append(IngredientInput())
                } label: {
                    Label("材料を追加", systemImage: "plus")
                }
            }

            Section("手順") {
                ForEach(steps.indices, id: \.self) { i in
                    HStack(alignment: .top, spacing: 8) {
                        Text("\(i + 1)")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 20, height: 20)
                            .background(.primary)
                            .clipShape(Circle())
                        TextField("手順を入力", text: $steps[i], axis: .vertical)
                            .lineLimit(2...6)
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
        .navigationTitle("レシピを編集")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                EditButton()
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("保存") {
                    save()
                }
                .bold()
                .disabled(!isValid)
            }
        }
    }

    private func save() {
        recipe.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        recipe.cookingTime = cookingTime
        recipe.weight = weight.rawValue
        recipe.ingredients = ingredients
            .map { $0.formattedText }
            .filter { !$0.isEmpty }
        recipe.steps = steps
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        try? modelContext.save()
        dismiss()
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

    static func parse(from text: String) -> IngredientInput {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return IngredientInput() }

        let tokens = trimmed.split(whereSeparator: \.isWhitespace).map(String.init)
        guard tokens.count >= 2 else {
            return IngredientInput(name: trimmed)
        }

        let tail = tokens.last ?? ""
        let name = tokens.dropLast().joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)
        let parsedTail = parseAmountAndUnit(from: tail)

        if !name.isEmpty && (!parsedTail.amount.isEmpty || parsedTail.unit != .none) {
            return IngredientInput(name: name, amount: parsedTail.amount, unit: parsedTail.unit)
        }
        return IngredientInput(name: trimmed)
    }

    private static func parseAmountAndUnit(from text: String) -> (amount: String, unit: IngredientUnit) {
        let t = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if t.isEmpty { return ("", .none) }

        let units = IngredientUnit.allCases.filter { $0 != .none }
            .sorted { $0.rawValue.count > $1.rawValue.count }

        for unit in units {
            if t.hasSuffix(unit.rawValue) {
                let amount = String(t.dropLast(unit.rawValue.count))
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                return (amount, unit)
            }
        }
        return (t, .none)
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
