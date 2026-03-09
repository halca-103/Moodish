//
//  AnalyzingView.swift
//  TasteLog
//
//  Created by Fukushima Haruka on 2026/03/05.
//
import SwiftUI

struct AnalyzingView: View {
    @Environment(\.dismiss) private var dismiss

    let image: UIImage
    var onComplete: (() -> Void)? = nil
    @State private var viewModel = ImageAnalysisViewModel()
    @State private var navigateToConfirm = false
    @State private var result: RecipeAnalysisResult?
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 0) {
            // 選んだ画像
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(height: 200)
                .clipped()
                .overlay {
                    if case .analyzing = viewModel.state {
                        ZStack {
                            Color.black.opacity(0.45)
                            VStack(spacing: 10) {
                                ProgressView()
                                    .tint(.white)
                                    .scaleEffect(1.4)
                                Text("AI が読み取り中...")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(.white)
                            }
                        }
                    }
                }

            // ステップ進捗
            VStack(alignment: .leading, spacing: 20) {
                Text("レシピを解析しています")
                    .font(.system(size: 17, weight: .bold))

                ForEach(viewModel.analysisSteps) { step in
                    HStack(spacing: 12) {
                        Image(systemName: step.isCompleted ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(step.isCompleted ? .green : .secondary)
                            .font(.system(size: 18))
                        Text(step.title)
                            .font(.system(size: 15))
                            .foregroundStyle(step.isCompleted ? .primary : .secondary)
                    }
                    .animation(.easeInOut, value: step.isCompleted)
                }

                if let errorMessage {
                    Text(errorMessage)
                        .font(.system(size: 13))
                        .foregroundStyle(.red)
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)

            Spacer()
        }
        .navigationBarBackButtonHidden(true)
        .navigationTitle("解析中")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $navigateToConfirm) {
            if let result {
                AnalysisResultView(
                    result: result,
                    image: image,
                    onRegistered: {
                        onComplete?()
                        dismiss()
                    }
                )
            }
        }
        .task {
            await viewModel.analyze(image: image)
            switch viewModel.state {
            case .success(let r):
                result = r
                navigateToConfirm = true
            case .failure(let e):
                errorMessage = UserFacingError.message(
                    for: e,
                    fallback: "画像の解析に失敗しました。別の画像で再度お試しください。"
                )
            default:
                break
            }
        }
    }
}
