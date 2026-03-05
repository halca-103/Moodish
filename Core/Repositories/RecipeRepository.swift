//
//  RecipeRepository.swift
//  TasteLog
//
//  Created by Fukushima Haruka on 2026/03/04.
//
import Foundation
import SwiftData

@Observable
class RecipeRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    // 全件取得
    func fetchAll() throws -> [Recipe] {
        let descriptor = FetchDescriptor<Recipe>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }

    // 重さでフィルタ
    func fetch(weight: Weight) throws -> [Recipe] {
        let weightValue = weight.rawValue
        let descriptor = FetchDescriptor<Recipe>(
            predicate: #Predicate { $0.weight == weightValue },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }

    // 保存
    func save(_ recipe: Recipe) throws {
        context.insert(recipe)
        try context.save()
    }

    // 削除
    func delete(_ recipe: Recipe) throws {
        context.delete(recipe)
        try context.save()
    }

    // 名前検索
    func search(query: String) throws -> [Recipe] {
        let descriptor = FetchDescriptor<Recipe>(
            predicate: #Predicate { $0.name.contains(query) },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }
}
