//
//  ImageAnalysisViewModel.swift
//  TasteLog
//
//  Created by Fukushima Haruka on 2026/03/05.
//

import SwiftUI

@Observable
class ImageAnalysisViewModel {
    enum State {
        case idle
        case analyzing
        case success(RecipeAnalysisResult)
        case failure(Error)
    }

    var state: State = .idle
    var analysisSteps: [AnalysisStep] = AnalysisStep.allSteps

    private let geminiService = GeminiService()

    func analyze(image: UIImage) async {
        state = .analyzing
        resetSteps()

        // 疑似プログレス：ステップを時間差で完了させる
        let stepTask = Task {
            await advanceSteps()
        }

        do {
            let result = try await geminiService.analyzeRecipeImage(image)
            stepTask.cancel()
            completeAllSteps()
            try? await Task.sleep(for: .milliseconds(400))
            state = .success(result)
        } catch {
            stepTask.cancel()
            state = .failure(error)
        }
    }

    // MARK: - Steps
    private func resetSteps() {
        analysisSteps = AnalysisStep.allSteps
    }

    private func advanceSteps() async {
        for i in analysisSteps.indices {
            try? await Task.sleep(for: .milliseconds(800))
            guard !Task.isCancelled else { return }
            analysisSteps[i].isCompleted = true
        }
    }

    private func completeAllSteps() {
        for i in analysisSteps.indices {
            analysisSteps[i].isCompleted = true
        }
    }
}

struct AnalysisStep: Identifiable {
    let id = UUID()
    let title: String
    var isCompleted: Bool = false

    static let allSteps = [
        AnalysisStep(title: "料理名を認識"),
        AnalysisStep(title: "材料を抽出"),
        AnalysisStep(title: "手順を整理"),
        AnalysisStep(title: "調理時間を推定"),
    ]
}
