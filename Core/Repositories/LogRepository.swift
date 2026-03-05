//
//  LogRepository.swift
//  TasteLog
//
//  Created by Fukushima Haruka on 2026/03/04.
//

import Foundation
import SwiftData

@Observable
class LogRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    // 全件取得（新しい順）
    func fetchAll() throws -> [CookingLog] {
        let descriptor = FetchDescriptor<CookingLog>(
            sortBy: [SortDescriptor(\.cookedAt, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }

    // 直近N件取得（ホーム画面の「最近の記録」用）
    func fetchRecent(limit: Int = 5) throws -> [CookingLog] {
        var descriptor = FetchDescriptor<CookingLog>(
            sortBy: [SortDescriptor(\.cookedAt, order: .reverse)]
        )
        descriptor.fetchLimit = limit
        return try context.fetch(descriptor)
    }

    // 特定レシピのログ取得（提案スコアリング用）
    func fetch(for recipe: Recipe) throws -> [CookingLog] {
        let recipeID = recipe.id
        let descriptor = FetchDescriptor<CookingLog>(
            predicate: #Predicate { $0.recipe?.id == recipeID },
            sortBy: [SortDescriptor(\.cookedAt, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }

    // 気分でフィルタ
    func fetch(mood: Mood) throws -> [CookingLog] {
        let moodValue = mood.rawValue
        let descriptor = FetchDescriptor<CookingLog>(
            predicate: #Predicate { $0.mood == moodValue }
        )
        return try context.fetch(descriptor)
    }

    // 保存
    func save(_ log: CookingLog) throws {
        context.insert(log)
        try context.save()
    }

    // 削除
    func delete(_ log: CookingLog) throws {
        context.delete(log)
        try context.save()
    }
}
