//
//  AllergyProfile.swift
//  TasteLog
//
//  Created by Fukushima Haruka on 2026/03/04.
//

import Foundation

struct AllergyProfile: Codable {
    var allergies: [String]       // 例: ["卵", "乳製品"]
    var dislikes: [String]        // 例: ["玉ねぎ"]

    static let defaultAllergies = ["卵", "乳製品", "えび", "そば", "落花生", "小麦"]

    // UserDefaults に保存・読み出し
    private static let key = "allergyProfile"

    static func load() -> AllergyProfile {
        guard let data = UserDefaults.standard.data(forKey: key),
              let profile = try? JSONDecoder().decode(AllergyProfile.self, from: data)
        else {
            return AllergyProfile(allergies: [], dislikes: [])
        }
        return profile
    }

    func save() {
        guard let data = try? JSONEncoder().encode(self) else { return }
        UserDefaults.standard.set(data, forKey: AllergyProfile.key)
    }
}
