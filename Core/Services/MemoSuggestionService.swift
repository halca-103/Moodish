import Foundation

enum MemoSuggestionService {
    private static let rules: [(keywords: [String], suggestion: String)] = [
        (["しょっぱい", "塩辛", "味が濃", "味濃", "濃すぎ"], "次回は調味料を1割ほど減らしてみませんか？"),
        (["薄い", "味が薄", "物足り"], "次回は仕上げに塩かしょうゆを少し足してみませんか？"),
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
}
