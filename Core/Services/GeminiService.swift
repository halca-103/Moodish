//
//  GeminiService.swift
//  TasteLog
//
//  Created by Fukushima Haruka on 2026/03/05.
//

import Foundation
import GoogleGenerativeAI
import UIKit

struct RecipeAnalysisResult: Codable {
    let name: String
    let cookingTime: Int
    let weight: String
    let ingredients: [String]
    let steps: [String]
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
          "ingredients": ["材料1", "材料2"],
          "steps": ["手順1", "手順2"]
        }

        画像がレシピでない場合や読み取れない場合も同じJSON形式で返し、
        nameに「不明」と入れてください。
        """

        let response = try await model.generateContent(prompt, image)
        guard let text = response.text else {
            throw GeminiError.emptyResponse
        }

        return try parseResponse(text)
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

        return try JSONDecoder().decode(RecipeAnalysisResult.self, from: data)
    }
}

enum GeminiError: LocalizedError {
    case emptyResponse
    case parseError

    var errorDescription: String? {
        switch self {
        case .emptyResponse: return "AIからの応答が空でした"
        case .parseError:    return "レシピ情報の読み取りに失敗しました"
        }
    }
}
