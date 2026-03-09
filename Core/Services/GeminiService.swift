//
//  GeminiService.swift
//  TasteLog
//
//  Created by Fukushima Haruka on 2026/03/05.
//

import Foundation
import GoogleGenerativeAI
import UIKit

struct RecognizedIngredient: Codable {
    let name: String
    let amount: String
    let unit: String

    var formattedText: String {
        let n = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let a = amount.trimmingCharacters(in: .whitespacesAndNewlines)
        let u = unit.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !n.isEmpty else { return "" }
        guard !a.isEmpty else { return n }
        return u.isEmpty ? "\(n) \(a)" : "\(n) \(a)\(u)"
    }
}

enum URLAnalysisPhase {
    case validatingURL
    case fetchingHTML
    case extractingRecipeText
    case aiAnalyzing
    case parsingResult
}

struct RecipeAnalysisResult: Codable {
    let name: String
    let cookingTime: Int
    let weight: String
    let ingredients: [String]
    let ingredientDetails: [RecognizedIngredient]
    let steps: [String]
    let recipeImageURL: String?

    enum CodingKeys: String, CodingKey {
        case name
        case cookingTime
        case weight
        case ingredients
        case ingredientDetails
        case steps
        case recipeImageURL
    }

    init(
        name: String,
        cookingTime: Int,
        weight: String,
        ingredients: [String],
        ingredientDetails: [RecognizedIngredient] = [],
        steps: [String],
        recipeImageURL: String? = nil
    ) {
        self.name = name
        self.cookingTime = cookingTime
        self.weight = weight
        self.ingredientDetails = ingredientDetails
        self.ingredients = ingredientDetails.isEmpty ? ingredients : ingredientDetails.map { $0.formattedText }.filter { !$0.isEmpty }
        self.steps = steps
        self.recipeImageURL = recipeImageURL
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        cookingTime = try container.decode(Int.self, forKey: .cookingTime)
        weight = try container.decode(String.self, forKey: .weight)
        steps = try container.decode([String].self, forKey: .steps)
        recipeImageURL = try container.decodeIfPresent(String.self, forKey: .recipeImageURL)

        // 新形式: ingredientDetails, または ingredients がオブジェクト配列
        if let details = try container.decodeIfPresent([RecognizedIngredient].self, forKey: .ingredientDetails) {
            ingredientDetails = details
            ingredients = details.map { $0.formattedText }.filter { !$0.isEmpty }
            return
        }
        if let details = try? container.decode([RecognizedIngredient].self, forKey: .ingredients) {
            ingredientDetails = details
            ingredients = details.map { $0.formattedText }.filter { !$0.isEmpty }
            return
        }

        // 旧形式: ingredients が文字列配列
        let raw = try container.decode([String].self, forKey: .ingredients)
        ingredientDetails = []
        ingredients = raw
    }
}

class GeminiService {
    private let model: GenerativeModel

    init() {
        //let apiKey = Bundle.main.infoDictionary?["GeminiAPIKey"] as? String ?? ""
        model = GenerativeModel(name: "gemini-2.5-flash", apiKey: "AIzaSyCcG7m5ItPCMIjQpJetS8s2KAMcGaTZpLk")
    }

    func analyzeRecipeImage(_ image: UIImage) async throws -> RecipeAnalysisResult {
        let prompt = """
        この画像からレシピ情報を読み取り、以下のJSON形式のみで返してください。
        他のテキストは一切含めないでください。

        {
          "name": "料理名",
          "cookingTime": 調理時間（分・整数）,
          "weight": "軽め" or "ふつう" or "ガッツリ",
          "ingredients": [
            { "name": "材料名", "amount": "数量", "unit": "単位" }
          ],
          "steps": ["手順1", "手順2"]
        }

        注意:
        - ingredients は必ずオブジェクト配列で返す
        - 例: {"name":"鶏むね肉","amount":"300","unit":"g"}
        - 手順は1ステップを短く区切って、長文を避ける

        画像がレシピでない場合や読み取れない場合も同じJSON形式で返し、
        nameに「不明」と入れてください。
        """

        let response = try await model.generateContent(prompt, image)
        guard let text = response.text else {
            throw GeminiError.emptyResponse
        }

        return try parseResponse(text)
    }
    func analyzeRecipeURL(
        _ urlString: String,
        onPhaseChange: ((URLAnalysisPhase) -> Void)? = nil
    ) async throws -> RecipeAnalysisResult {
        // HTML取得
        onPhaseChange?(.validatingURL)
        guard let url = URL(string: urlString) else {
            throw GeminiError.invalidURL
        }

        onPhaseChange?(.fetchingHTML)
        let (data, _) = try await URLSession.shared.data(from: url)
        guard let html = String(data: data, encoding: .utf8) ??
                         String(data: data, encoding: .shiftJIS) else {
            throw GeminiError.fetchFailed
        }
        let imageURL = extractRecipeImageURL(from: html, baseURL: url)

        // HTMLタグを除去してテキストだけ抽出
        onPhaseChange?(.extractingRecipeText)
        let cleaned = html
            .replacingOccurrences(of: "<[^>]+>", with: " ", options: .regularExpression)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        // 長すぎる場合は先頭8000文字だけ使う
        let truncated = String(cleaned.prefix(8000))

        let prompt = """
        以下のテキストはレシピサイトから取得したものです。
        レシピ情報を読み取り、以下のJSON形式のみで返してください。
        他のテキストは一切含めないでください。

        {
          "name": "料理名",
          "cookingTime": 調理時間（分・整数）,
          "weight": "軽め" or "ふつう" or "ガッツリ",
          "ingredients": [
            { "name": "材料名", "amount": "数量", "unit": "単位" }
          ],
          "steps": ["手順1", "手順2"]
        }

        注意:
        - ingredients は必ずオブジェクト配列で返す
        - 例: {"name":"玉ねぎ","amount":"1","unit":"個"}
        - 手順は1ステップを短く区切って、長文を避ける

        テキスト：
        \(truncated)
        """

        onPhaseChange?(.aiAnalyzing)
        let response = try await model.generateContent(prompt)
        guard let text = response.text else {
            throw GeminiError.emptyResponse
        }

        onPhaseChange?(.parsingResult)
        let parsed = try parseResponse(text)
        return RecipeAnalysisResult(
            name: parsed.name,
            cookingTime: parsed.cookingTime,
            weight: parsed.weight,
            ingredients: parsed.ingredients,
            ingredientDetails: parsed.ingredientDetails,
            steps: parsed.steps,
            recipeImageURL: imageURL ?? parsed.recipeImageURL
        )
    }

    private func parseResponse(_ text: String) throws -> RecipeAnalysisResult {
        // ```json ``` マークダウンを除去
        let cleaned = text
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let data = cleaned.data(using: .utf8) else {
            throw GeminiError.parseError
        }

        let decoded = try JSONDecoder().decode(RecipeAnalysisResult.self, from: data)
        let normalizedSteps = splitLongSteps(decoded.steps)
        return RecipeAnalysisResult(
            name: decoded.name,
            cookingTime: decoded.cookingTime,
            weight: decoded.weight,
            ingredients: decoded.ingredients,
            ingredientDetails: decoded.ingredientDetails,
            steps: normalizedSteps,
            recipeImageURL: decoded.recipeImageURL
        )
    }

    private func splitLongSteps(_ steps: [String]) -> [String] {
        var output: [String] = []
        for step in steps {
            let text = step.trimmingCharacters(in: .whitespacesAndNewlines)
            if text.count <= 80 {
                output.append(text)
                continue
            }

            let parts = text
                .replacingOccurrences(of: "。", with: "。\n")
                .replacingOccurrences(of: "、", with: "、\n")
                .split(separator: "\n")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }

            if parts.count > 1 {
                output.append(contentsOf: parts)
            } else {
                output.append(text)
            }
        }
        return output
    }

    private func extractRecipeImageURL(from html: String, baseURL: URL) -> String? {
        // og:image / twitter:image を優先
        let patterns = [
            #"<meta[^>]+property=["']og:image["'][^>]+content=["']([^"']+)["']"#,
            #"<meta[^>]+content=["']([^"']+)["'][^>]+property=["']og:image["']"#,
            #"<meta[^>]+name=["']twitter:image["'][^>]+content=["']([^"']+)["']"#,
            #"<meta[^>]+content=["']([^"']+)["'][^>]+name=["']twitter:image["']"#
        ]

        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]),
               let match = regex.firstMatch(in: html, range: NSRange(html.startIndex..., in: html)),
               let range = Range(match.range(at: 1), in: html) {
                let raw = String(html[range])
                if let absolute = URL(string: raw, relativeTo: baseURL)?.absoluteURL {
                    return absolute.absoluteString
                }
            }
        }

        return nil
    }
}

//enum GeminiError: LocalizedError {
//    case emptyResponse
//    case parseError
//
//    var errorDescription: String? {
//        switch self {
//        case .emptyResponse: return "AIからの応答が空でした"
//        case .parseError:    return "レシピ情報の読み取りに失敗しました"
//        }
//    }
//}
enum GeminiError: LocalizedError {
    case emptyResponse
    case parseError
    case invalidURL      // ← 追加
    case fetchFailed     // ← 追加

    var errorDescription: String? {
        switch self {
        case .emptyResponse: return "AIからの応答が空でした"
        case .parseError:    return "レシピ情報の読み取りに失敗しました"
        case .invalidURL:    return "URLの形式が正しくありません"
        case .fetchFailed:   return "URLの読み取りに失敗しました"
        }
    }
}
