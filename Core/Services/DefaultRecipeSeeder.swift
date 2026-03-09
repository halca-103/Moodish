import Foundation
import SwiftData

enum DefaultRecipeSeeder {
    static func seedIfNeeded(in context: ModelContext) throws {
        var descriptor = FetchDescriptor<Recipe>()
        descriptor.fetchLimit = 1
        let hasAnyRecipe = try !context.fetch(descriptor).isEmpty
        if hasAnyRecipe { return }

        for recipe in defaultRecipes {
            context.insert(recipe)
        }
        try context.save()
    }

    static func removeSeededRecipes(in context: ModelContext) throws {
        let descriptor = FetchDescriptor<Recipe>(
            predicate: #Predicate { $0.isDefaultSeed == true }
        )
        let recipes = try context.fetch(descriptor)
        for recipe in recipes {
            context.delete(recipe)
        }
        try context.save()
    }

    static func seededCount(in context: ModelContext) throws -> Int {
        let descriptor = FetchDescriptor<Recipe>(
            predicate: #Predicate { $0.isDefaultSeed == true }
        )
        return try context.fetchCount(descriptor)
    }

    private static var defaultRecipes: [Recipe] {
        [
            Recipe(
                name: "鶏むねの塩レモン蒸し",
                cookingTime: 20,
                weight: .light,
                ingredients: ["鶏むね肉 300g", "塩 小さじ1/2", "レモン汁 大さじ1", "オリーブオイル 小さじ1"],
                steps: [
                    "鶏むね肉に塩をふって10分置く",
                    "耐熱皿に入れてレモン汁とオリーブオイルをかける",
                    "ふんわりラップをして電子レンジで加熱する",
                    "火が通ったら薄切りにして盛り付ける"
                ],
                isDefaultSeed: true
            ),
            Recipe(
                name: "豚こま生姜焼き",
                cookingTime: 15,
                weight: .normal,
                ingredients: ["豚こま肉 250g", "玉ねぎ 1/2個", "醤油 大さじ1.5", "みりん 大さじ1", "生姜チューブ 3cm"],
                steps: [
                    "玉ねぎを薄切りにする",
                    "フライパンで豚こま肉を炒める",
                    "玉ねぎを加えてしんなりするまで炒める",
                    "調味料を加えて全体に絡める"
                ],
                isDefaultSeed: true
            ),
            Recipe(
                name: "野菜たっぷりキーマカレー",
                cookingTime: 30,
                weight: .heavy,
                ingredients: ["合い挽き肉 250g", "玉ねぎ 1個", "にんじん 1/2本", "カレールウ 2片", "水 250ml"],
                steps: [
                    "玉ねぎとにんじんをみじん切りにする",
                    "ひき肉を炒めて色が変わったら野菜を加える",
                    "水を加えて5分煮る",
                    "火を止めてルウを溶かし、再加熱してとろみをつける"
                ],
                isDefaultSeed: true
            )
        ]
    }
}
