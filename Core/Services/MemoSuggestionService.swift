import Foundation

enum MemoSuggestionService {
    private static let saltyKeywords = ["しょっぱい", "塩辛", "味が濃", "味濃", "濃すぎ"]
    private static let lightKeywords = ["薄い", "味が薄", "物足り"]
    private static let rules: [(keywords: [String], suggestion: String)] = [
        (saltyKeywords, "次回は調味料を1割ほど減らしてみませんか？"),
        (lightKeywords, "次回は仕上げに塩かしょうゆを少し足してみませんか？"),
        (["固い", "かたい", "パサ", "パサつ"], "次回は加熱時間を1〜2分短くしてみませんか？"),
        (["水っぽ", "べちゃ", "べちょ"], "次回は水分を少し減らして最後に1分しっかり加熱してみませんか？"),
        (["焦げ", "こげ", "焼きすぎ"], "次回は火加減を1段階弱めてみませんか？"),
        (["生焼け", "火が通", "半生"], "次回は最初の加熱を1〜2分だけ追加してみませんか？"),
        (["時間かかった", "手間", "面倒"], "次回は先に下ごしらえだけまとめておきませんか？")
    ]

    static func suggestion(for recipe: Recipe, logs: [CookingLog]) -> String? {
        let recipeLogs = logs
            .filter { $0.recipe?.id == recipe.id }
            .sorted { $0.cookedAt > $1.cookedAt }

        let memoLogs = recipeLogs.filter { !$0.memo.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        guard !memoLogs.isEmpty else { return nil }

        for log in memoLogs {
            let memo = log.memo
            if let detailed = seasoningAmountSuggestion(from: memo) {
                return detailed
            }
            if let detailedFromIngredients = seasoningAmountSuggestion(
                fromRecipeIngredients: recipe.ingredients,
                memo: memo
            ) {
                return detailedFromIngredients
            }
            if let matched = rules.first(where: { rule in
                rule.keywords.contains(where: { memo.localizedCaseInsensitiveContains($0) })
            }) {
                return matched.suggestion
            }
        }

        if let lowRated = recipeLogs.first(where: { $0.rating <= 2 }) {
            if !lowRated.memo.isEmpty {
                return "前回メモを踏まえて、手順の火加減か加熱時間を少し調整してみませんか？"
            }
            return "前回は評価が低めでした。調味料量を少しだけ調整してみませんか？"
        }

        return "前回のメモを見返して、気になった工程を1つだけ変えてみませんか？"
    }

    private static func seasoningAmountSuggestion(from memo: String) -> String? {
        let isTooSalty = saltyKeywords.contains { memo.localizedCaseInsensitiveContains($0) }
        let isTooLight = lightKeywords.contains { memo.localizedCaseInsensitiveContains($0) }
        guard isTooSalty || isTooLight else { return nil }

        let pattern = #"(塩|しょうゆ|醤油|味噌|みそ)\D{0,8}(\d+(?:\.\d+)?)\s*(大さじ|小さじ)"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let nsMemo = memo as NSString
        let range = NSRange(location: 0, length: nsMemo.length)

        guard let match = regex.firstMatch(in: memo, options: [], range: range),
              match.numberOfRanges == 4 else {
            return nil
        }

        let seasoning = nsMemo.substring(with: match.range(at: 1))
        let amountText = nsMemo.substring(with: match.range(at: 2))
        let unit = nsMemo.substring(with: match.range(at: 3))
        guard let amount = Double(amountText) else { return nil }

        if isTooSalty {
            let delta = unit == "大さじ" ? 1.0 : 0.5
            let minAmount = unit == "大さじ" ? 0.5 : 0.25
            let adjusted = max(minAmount, amount - delta)
            if adjusted < amount {
                return "\(seasoning)を\(format(amount))\(unit)ではなく\(format(adjusted))\(unit)にしてみませんか？"
            }
        }

        if isTooLight {
            let delta = unit == "大さじ" ? 0.5 : 0.25
            let adjusted = amount + delta
            return "\(seasoning)を\(format(amount))\(unit)ではなく\(format(adjusted))\(unit)にしてみませんか？"
        }

        return nil
    }

    private static func seasoningAmountSuggestion(fromRecipeIngredients ingredients: [String], memo: String) -> String? {
        let isTooSalty = saltyKeywords.contains { memo.localizedCaseInsensitiveContains($0) }
        let isTooLight = lightKeywords.contains { memo.localizedCaseInsensitiveContains($0) }
        guard isTooSalty || isTooLight else { return nil }

        let candidates = ingredients.compactMap { extractSeasoningAmount(from: $0) }
        guard let target = candidates.first else { return nil }

        if isTooSalty {
            let delta = target.unit == "大さじ" ? 1.0 : 0.5
            let minAmount = target.unit == "大さじ" ? 0.5 : 0.25
            let adjusted = max(minAmount, target.amount - delta)
            if adjusted < target.amount {
                return "前回メモをふまえて、\(target.seasoning)を\(format(target.amount))\(target.unit)ではなく\(format(adjusted))\(target.unit)にしてみませんか？"
            }
        }

        if isTooLight {
            let delta = target.unit == "大さじ" ? 0.5 : 0.25
            let adjusted = target.amount + delta
            return "前回メモをふまえて、\(target.seasoning)を\(format(target.amount))\(target.unit)ではなく\(format(adjusted))\(target.unit)にしてみませんか？"
        }

        return nil
    }

    private static func extractSeasoningAmount(from ingredient: String) -> (seasoning: String, amount: Double, unit: String)? {
        let pattern = #"(塩|しょうゆ|醤油|味噌|みそ)\D{0,8}(\d+(?:\.\d+)?)\s*(大さじ|小さじ)"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let nsText = ingredient as NSString
        let range = NSRange(location: 0, length: nsText.length)
        guard let match = regex.firstMatch(in: ingredient, options: [], range: range),
              match.numberOfRanges == 4 else {
            return nil
        }
        let seasoning = nsText.substring(with: match.range(at: 1))
        let amountText = nsText.substring(with: match.range(at: 2))
        let unit = nsText.substring(with: match.range(at: 3))
        guard let amount = Double(amountText) else { return nil }
        return (seasoning, amount, unit)
    }

    private static func format(_ value: Double) -> String {
        if value.truncatingRemainder(dividingBy: 1) == 0 {
            return String(Int(value))
        }
        return String(format: "%.1f", value)
    }
}
