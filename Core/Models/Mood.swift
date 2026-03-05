//
//  Mood.swift
//  TasteLog
//
//  Created by Fukushima Haruka on 2026/03/04.
//

import Foundation

enum Mood: String, Codable, CaseIterable, Identifiable {
    case energetic   = "元気"
    case okay        = "まあまあ"
    case exhausted   = "ヘトヘト"
    case sick        = "風邪気味"
    case stressed    = "ストレス"
    case starving    = "腹ペコ"

    var id: String { rawValue }

    var emoji: String {
        switch self {
        case .energetic: return "😊"
        case .okay:      return "😐"
        case .exhausted: return "😴"
        case .sick:      return "🤧"
        case .stressed:  return "😤"
        case .starving:  return "😋"
        }
    }
}

enum Weight: String, Codable, CaseIterable, Identifiable {
    case light  = "軽め"
    case normal = "ふつう"
    case heavy  = "ガッツリ"

    var id: String { rawValue }

    var emoji: String {
        switch self {
        case .light:  return "🥗"
        case .normal: return "🍱"
        case .heavy:  return "🍖"
        }
    }
}
