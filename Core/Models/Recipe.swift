//
//  Recipe.swift
//  TasteLog
//
//  Created by Fukushima Haruka on 2026/03/04.
//

import Foundation
import SwiftData

@Model
class Recipe {
    var id: UUID
    var name: String
    var cookingTime: Int          // 分
    var weight: String            // Weight.rawValue
    var ingredients: [String]
    var steps: [String]
    var recipeImageURL: String?   // レシピ写真（AI解析用）
    var dishImageURL: String?     // 料理写真（サムネ用）
    var isDefaultSeed: Bool = false
    var createdAt: Date

    // Relationship
    @Relationship(deleteRule: .cascade)
    var logs: [CookingLog] = []

    init(
        id: UUID = UUID(),
        name: String,
        cookingTime: Int = 15,
        weight: Weight = .normal,
        ingredients: [String] = [],
        steps: [String] = [],
        recipeImageURL: String? = nil,
        dishImageURL: String? = nil,
        isDefaultSeed: Bool = false,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.cookingTime = cookingTime
        self.weight = weight.rawValue
        self.ingredients = ingredients
        self.steps = steps
        self.recipeImageURL = recipeImageURL
        self.dishImageURL = dishImageURL
        self.isDefaultSeed = isDefaultSeed
        self.createdAt = createdAt
    }

    var weightEnum: Weight {
        Weight(rawValue: weight) ?? .normal
    }
}
