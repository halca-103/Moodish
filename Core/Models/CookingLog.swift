//
//  CookingLog.swift
//  TasteLog
//
//  Created by Fukushima Haruka on 2026/03/04.
//
import Foundation
import SwiftData

@Model
class CookingLog {
    var id: UUID
    var cookedAt: Date
    var mood: String              // Mood.rawValue
    var rating: Int               // 1〜5
    var memo: String

    // HealthKit data（任意）
    var sleepHours: Double?       // 前日の睡眠時間
    //var stepCount: Int?           // 当日の歩数

    // Relationship
    var recipe: Recipe?

    init(
        id: UUID = UUID(),
        cookedAt: Date = Date(),
        mood: Mood,
        rating: Int = 0,
        memo: String = "",
        sleepHours: Double? = nil,
        stepCount: Int? = nil,
        recipe: Recipe? = nil
    ) {
        self.id = id
        self.cookedAt = cookedAt
        self.mood = mood.rawValue
        self.rating = rating
        self.memo = memo
        self.sleepHours = sleepHours
        //self.stepCount = stepCount
        self.recipe = recipe
    }

    var moodEnum: Mood {
        Mood(rawValue: mood) ?? .okay
    }
}
