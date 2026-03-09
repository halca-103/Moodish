//
//  URLInputView.swift
//  TasteLog
//
//  Created by Fukushima Haruka on 2026/03/05.
//
import SwiftUI
import SwiftData

struct URLInputView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var urlText = ""
    @State private var isLoading = false
    @State private var errorMessage: String? = nil
    @State private var result: RecipeAnalysisResult? = nil
    @State private var navigateToConfirm = false
    @State private var analysisSteps: [AnalysisStep] = [
        AnalysisStep(title: "URLを確認"),
        AnalysisStep(title: "ページ情報を取得"),
        AnalysisStep(title: "レシピ本文を抽出"),
        AnalysisStep(title: "AIがレシピを解析"),
        AnalysisStep(title: "結果を整形")
    ]
    @State private var targetCompletedIndex = -1
    @State private var displayedCompletedIndex = -1
    @State private var stepAnimationTask: Task<Void, Never>? = nil
    private let supportedSites: [(name: String, url: String)] = [
        ("クックパッド", "https://cookpad.com"),
        ("デリッシュキッチン", "https://delishkitchen.tv"),
        ("レタスクラブ", "https://www.lettuceclub.net"),
        ("Kurashiru", "https://www.kurashiru.com"),
        ("Instagram", "https://www.instagram.com"),
        ("YouTube", "https://www.youtube.com")
    ]

    private let gemini = GeminiService()

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {

            // 説明
            VStack(alignment: .leading, spacing: 6) {
                Text("レシピのURLを貼り付けてください")
                    .font(.system(size: 15, weight: .semibold))
                Text("クックパッド・Instagram・YouTubeなど\nURLの貼り付けに対応しています")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .lineSpacing(3)
            }

            // URL入力
            HStack(spacing: 10) {
                Image(systemName: "link")
                    .foregroundStyle(.secondary)
                TextField("https://cookpad.com/...", text: $urlText)
                    .keyboardType(.URL)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                if !urlText.isEmpty {
                    Button {
                        urlText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(14)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            // エラー
            if let errorMessage {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.circle")
                        .foregroundStyle(.red)
                    Text(errorMessage)
                        .font(.system(size: 13))
                        .foregroundStyle(.red)
                }
            }

            if isLoading {
                VStack(alignment: .leading, spacing: 12) {
                    Text("URLを解析しています")
                        .font(.system(size: 15, weight: .semibold))
                    ForEach(analysisSteps) { step in
                        HStack(spacing: 10) {
                            Image(systemName: step.isCompleted ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(step.isCompleted ? .green : .secondary)
                            Text(step.title)
                                .font(.system(size: 14))
                                .foregroundStyle(step.isCompleted ? .primary : .secondary)
                        }
                    }
                }
                .padding(14)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            // 対応サイト例
            VStack(alignment: .leading, spacing: 8) {
                Text("対応サイト例")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                FlowLayout(spacing: 8) {
                    ForEach(supportedSites, id: \.name) { site in
                        Link(destination: URL(string: site.url)!) {
                            Text(site.name)
                                .font(.system(size: 12))
                                .foregroundStyle(AppTheme.accent)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(AppTheme.accentBg)
                                .clipShape(Capsule())
                        }
                    }
                }
            }

            Spacer()

            // 読み取るボタン
            Button {
                Task { await analyze() }
            } label: {
                HStack {
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                            .scaleEffect(0.8)
                    }
                    Text(isLoading ? "読み取り中..." : "読み取る")
                        .font(.system(size: 16, weight: .bold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(urlText.isEmpty || isLoading ? Color.secondary : Color.primary)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .disabled(urlText.isEmpty || isLoading)
        }
        .padding(20)
        .navigationTitle("URLから登録")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $navigateToConfirm) {
            if let result {
                AnalysisResultView(
                    result: result,
                    image: UIImage(),
                    aiBadgeText: "AI URL解析済み（精度確認用）"
                )
            }
        }
    }

    private func analyze() async {
        errorMessage = nil
        isLoading = true
        resetAnalysisSteps()
        defer {
            isLoading = false
            stepAnimationTask?.cancel()
            stepAnimationTask = nil
        }

        do {
            let parsed = try await gemini.analyzeRecipeURL(urlText) { phase in
                Task { @MainActor in
                    completeSteps(upTo: phase)
                }
            }
            await MainActor.run {
                completeSteps(upTo: .parsingResult)
            }
            try? await Task.sleep(for: .milliseconds(450))
            result = parsed
            navigateToConfirm = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func resetAnalysisSteps() {
        for i in analysisSteps.indices {
            analysisSteps[i].isCompleted = false
        }
        targetCompletedIndex = -1
        displayedCompletedIndex = -1
        stepAnimationTask?.cancel()
        stepAnimationTask = Task {
            await animateStepProgress()
        }
    }

    private func completeSteps(upTo phase: URLAnalysisPhase) {
        let index: Int
        switch phase {
        case .validatingURL:
            index = 0
        case .fetchingHTML:
            index = 1
        case .extractingRecipeText:
            index = 2
        case .aiAnalyzing:
            index = 3
        case .parsingResult:
            index = 4
        }

        targetCompletedIndex = max(targetCompletedIndex, min(index, analysisSteps.count - 1))
    }

    @MainActor
    private func animateStepProgress() async {
        while !Task.isCancelled {
            if displayedCompletedIndex < targetCompletedIndex {
                displayedCompletedIndex += 1
                if displayedCompletedIndex >= 0 && displayedCompletedIndex < analysisSteps.count {
                    analysisSteps[displayedCompletedIndex].isCompleted = true
                }
                try? await Task.sleep(for: .milliseconds(300))
            } else {
                try? await Task.sleep(for: .milliseconds(100))
            }
        }
    }
}
