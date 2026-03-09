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
    var name: String
    var amount: String
    var unit: String

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
    let sourceURL: String?

    enum CodingKeys: String, CodingKey {
        case name
        case cookingTime
        case weight
        case ingredients
        case ingredientDetails
        case steps
        case recipeImageURL
        case sourceURL
    }

    init(
        name: String,
        cookingTime: Int,
        weight: String,
        ingredients: [String],
        ingredientDetails: [RecognizedIngredient] = [],
        steps: [String],
        recipeImageURL: String? = nil,
        sourceURL: String? = nil
    ) {
        self.name = name
        self.cookingTime = cookingTime
        self.weight = weight
        self.ingredientDetails = ingredientDetails
        self.ingredients = ingredientDetails.isEmpty ? ingredients : ingredientDetails.map { $0.formattedText }.filter { !$0.isEmpty }
        self.steps = steps
        self.recipeImageURL = recipeImageURL
        self.sourceURL = sourceURL
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        cookingTime = try container.decode(Int.self, forKey: .cookingTime)
        weight = try container.decode(String.self, forKey: .weight)
        steps = try container.decode([String].self, forKey: .steps)
        recipeImageURL = try container.decodeIfPresent(String.self, forKey: .recipeImageURL)
        sourceURL = try container.decodeIfPresent(String.self, forKey: .sourceURL)

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
        - amount と unit はなるべく埋める（例: 1個, 200g, 大さじ2）
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

    func generateMemoBasedSuggestion(
        recipeName: String,
        ingredients: [String],
        steps: [String],
        recentMemos: [String]
    ) async throws -> String {
        let memoText = recentMemos.isEmpty ? "（メモなし）" : recentMemos.joined(separator: "\n- ")
        let ingredientText = ingredients.isEmpty ? "（材料情報なし）" : ingredients.joined(separator: "、")
        let stepText = steps.isEmpty ? "（手順情報なし）" : steps.prefix(4).joined(separator: " → ")

        let prompt = """
        あなたは料理改善アシスタントです。
        以下の情報を元に、次回の料理で試せる改善提案を日本語で1文だけ出してください。

        料理名: \(recipeName)
        材料: \(ingredientText)
        主な手順: \(stepText)
        直近メモ:
        - \(memoText)

        ルール:
        - 出力は1文のみ、60文字以内
        - 可能なら数量を含めて具体化する（例: 塩を大さじ3→2）
        - 曖昧なら火加減・加熱時間・切り方など具体行動にする
        - 先頭は「次回は」で始める
        - 余計な説明・箇条書き・記号は不要
        """

        let response = try await model.generateContent(prompt)
        guard let text = response.text else {
            throw GeminiError.emptyResponse
        }
        return normalizeSuggestionText(text)
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
        let data = try await fetchHTMLData(from: url)
        guard let html = String(data: data, encoding: .utf8) ??
                         String(data: data, encoding: .shiftJIS) else {
            throw GeminiError.fetchFailed
        }
        let imageURL = extractRecipeImageURL(from: html, baseURL: url)

        // HTMLテキスト抽出（YouTubeは専用抽出）
        onPhaseChange?(.extractingRecipeText)
        let cleaned: String
        if isYouTubeURL(url) {
            cleaned = extractYouTubeRecipeText(from: html, url: url)
        } else {
            cleaned = html
                .replacingOccurrences(of: "<[^>]+>", with: " ", options: .regularExpression)
                .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }

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
        - amount と unit はなるべく埋める（例: 1個, 200g, 大さじ2）
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
            recipeImageURL: imageURL ?? parsed.recipeImageURL,
            sourceURL: urlString
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
        let normalizedIngredients = normalizeIngredients(
            details: decoded.ingredientDetails,
            rawIngredients: decoded.ingredients
        )
        let normalizedSteps = splitLongSteps(decoded.steps)
        return RecipeAnalysisResult(
            name: decoded.name,
            cookingTime: decoded.cookingTime,
            weight: decoded.weight,
            ingredients: normalizedIngredients.map { $0.formattedText },
            ingredientDetails: normalizedIngredients,
            steps: normalizedSteps,
            recipeImageURL: decoded.recipeImageURL,
            sourceURL: decoded.sourceURL
        )
    }

    private func normalizeIngredients(details: [RecognizedIngredient], rawIngredients: [String]) -> [RecognizedIngredient] {
        let source: [RecognizedIngredient]
        if details.isEmpty {
            source = rawIngredients.map { RecognizedIngredient(name: $0, amount: "", unit: "") }
        } else {
            source = details
        }

        return source.map { ingredient in
            var item = ingredient
            item.name = item.name.trimmingCharacters(in: .whitespacesAndNewlines)
            item.amount = item.amount.trimmingCharacters(in: .whitespacesAndNewlines)
            item.unit = item.unit.trimmingCharacters(in: .whitespacesAndNewlines)

            if !item.amount.isEmpty && item.unit.isEmpty,
               let split = splitAmountAndUnit(item.amount) {
                item.amount = split.amount
                item.unit = split.unit
            }

            if (item.amount.isEmpty || item.unit.isEmpty),
               let parsed = parseIngredientText(item.name) {
                if item.name.isEmpty { item.name = parsed.name }
                if item.amount.isEmpty { item.amount = parsed.amount }
                if item.unit.isEmpty { item.unit = parsed.unit }
                if !parsed.name.isEmpty { item.name = parsed.name }
            }

            if item.amount == "適量" && item.unit.isEmpty {
                item.unit = "適量"
            }
            return item
        }
    }

    private func splitAmountAndUnit(_ text: String) -> (amount: String, unit: String)? {
        let t = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else { return nil }
        let pattern = #"^([0-9０-９]+(?:[./／][0-9０-９]+)?(?:\.[0-9]+)?)\s*(g|kg|ml|mL|cc|L|個|本|枚|袋|缶|パック|片|合|大さじ|小さじ|カップ)$"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]),
              let match = regex.firstMatch(in: t, range: NSRange(t.startIndex..., in: t)),
              let amountRange = Range(match.range(at: 1), in: t),
              let unitRange = Range(match.range(at: 2), in: t) else {
            return nil
        }
        return (String(t[amountRange]), String(t[unitRange]))
    }

    private func parseIngredientText(_ text: String) -> (name: String, amount: String, unit: String)? {
        let t = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else { return nil }
        let pattern = #"^(.+?)\s*([0-9０-９]+(?:[./／][0-9０-９]+)?(?:\.[0-9]+)?)\s*(g|kg|ml|mL|cc|L|個|本|枚|袋|缶|パック|片|合|大さじ|小さじ|カップ)$"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]),
              let match = regex.firstMatch(in: t, range: NSRange(t.startIndex..., in: t)),
              let nameRange = Range(match.range(at: 1), in: t),
              let amountRange = Range(match.range(at: 2), in: t),
              let unitRange = Range(match.range(at: 3), in: t) else {
            return nil
        }
        return (
            name: String(t[nameRange]).trimmingCharacters(in: .whitespacesAndNewlines),
            amount: String(t[amountRange]),
            unit: String(t[unitRange])
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

    private func isYouTubeURL(_ url: URL) -> Bool {
        guard let host = url.host?.lowercased() else { return false }
        return host.contains("youtube.com") || host.contains("youtu.be")
    }

    private func extractYouTubeRecipeText(from html: String, url: URL) -> String {
        var parts: [String] = []
        parts.append("YouTube URL: \(url.absoluteString)")

        if let title = extractMetaContent(from: html, property: "og:title") {
            parts.append("動画タイトル: \(title)")
        }

        if let description = extractYouTubeShortDescription(from: html), !description.isEmpty {
            parts.append("概要欄: \(description)")
        } else if let metaDescription = extractMetaContent(from: html, property: "og:description") {
            parts.append("概要: \(metaDescription)")
        }

        if let keywords = extractMetaContent(from: html, property: "keywords") {
            parts.append("キーワード: \(keywords)")
        }

        return parts.joined(separator: "\n")
    }

    private func extractMetaContent(from html: String, property: String) -> String? {
        let escaped = NSRegularExpression.escapedPattern(for: property)
        let patterns = [
            #"<meta[^>]+property=["']\#(escaped)["'][^>]+content=["']([^"']+)["']"#,
            #"<meta[^>]+name=["']\#(escaped)["'][^>]+content=["']([^"']+)["']"#,
            #"<meta[^>]+content=["']([^"']+)["'][^>]+property=["']\#(escaped)["']"#,
            #"<meta[^>]+content=["']([^"']+)["'][^>]+name=["']\#(escaped)["']"#
        ]

        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]),
               let match = regex.firstMatch(in: html, range: NSRange(html.startIndex..., in: html)),
               let range = Range(match.range(at: 1), in: html) {
                return String(html[range]).trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        return nil
    }

    private func extractYouTubeShortDescription(from html: String) -> String? {
        let pattern = #""shortDescription":"((?:\\.|[^"\\])*)""#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []),
              let match = regex.firstMatch(in: html, range: NSRange(html.startIndex..., in: html)),
              let range = Range(match.range(at: 1), in: html) else {
            return nil
        }

        let raw = String(html[range])
        let unescaped = unescapeJSONString(raw)
            .replacingOccurrences(of: "\r", with: "\n")
            .replacingOccurrences(of: "\n\n\n+", with: "\n\n", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return unescaped.isEmpty ? nil : unescaped
    }

    private func unescapeJSONString(_ text: String) -> String {
        // JSON文字列としてデコードして \n や \uXXXX を復元
        let wrapped = "\"\(text.replacingOccurrences(of: "\"", with: "\\\""))\""
        guard let data = wrapped.data(using: .utf8),
              let decoded = try? JSONDecoder().decode(String.self, from: data) else {
            return text
        }
        return decoded
    }

    private func fetchHTMLData(from url: URL) async throws -> Data {
        var request = URLRequest(url: url)
        request.timeoutInterval = 20
        request.setValue(
            "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1",
            forHTTPHeaderField: "User-Agent"
        )
        request.setValue("ja,en-US;q=0.9,en;q=0.8", forHTTPHeaderField: "Accept-Language")
        request.setValue("text/html,application/xhtml+xml", forHTTPHeaderField: "Accept")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            return data
        }
        if (200..<400).contains(http.statusCode) {
            return data
        }
        throw GeminiError.fetchFailed
    }

    private func normalizeSuggestionText(_ text: String) -> String {
        let noMarkdown = text
            .replacingOccurrences(of: "```", with: "")
            .replacingOccurrences(of: "*", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let firstLine = noMarkdown
            .components(separatedBy: .newlines)
            .first?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? noMarkdown

        if firstLine.hasPrefix("次回は") {
            return firstLine
        }
        return "次回は\(firstLine)"
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
