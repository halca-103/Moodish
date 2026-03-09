//
//  TimerView.swift
//  TasteLog
//
//  Created by Fukushima Haruka on 2026/03/05.
//
import SwiftUI
import SwiftData

struct TimerView: View {
    let recipe: Recipe
    let mood: Mood

    @Query(sort: \CookingLog.cookedAt, order: .reverse) private var allLogs: [CookingLog]
    private let gemini = GeminiService()
    @State private var elapsedSeconds: Int
    @State private var isRunning = false
    @State private var currentStep = 0
    @State private var navigateToLog = false
    @State private var timer: Timer? = nil
    @State private var showOverview = true
    @State private var aiSuggestion: String? = nil
    @State private var isGeneratingSuggestion = false

    init(recipe: Recipe, mood: Mood) {
        self.recipe = recipe
        self.mood = mood
        _elapsedSeconds = State(initialValue: 0)
    }

    var formattedTime: String {
        let m = elapsedSeconds / 60
        let s = elapsedSeconds % 60
        return String(format: "%02d:%02d", m, s)
    }

    var progress: Double {
        let total = recipe.cookingTime * 60
        guard total > 0 else { return 0 }
        return min(Double(elapsedSeconds) / Double(total), 1.0)
    }

    private var nextSuggestion: String? {
        MemoSuggestionService.suggestion(for: recipe, logs: allLogs)
    }

    private var suggestionText: String? {
        aiSuggestion ?? nextSuggestion
    }

    var body: some View {
        VStack(spacing: 32) {

            // タイマー円
            ZStack {
                Circle()
                    .stroke(Color(.systemGray5), lineWidth: 12)
                    .frame(width: 200, height: 200)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(Color.primary, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .frame(width: 200, height: 200)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: progress)
                VStack(spacing: 8) {
                    Text(formattedTime)
                        .font(.system(size: 44, weight: .bold, design: .monospaced))
                    Button {
                        toggleTimer()
                    } label: {
                        Text(isRunning ? "一時停止" : "開始")
                            .font(.system(size: 13, weight: .semibold))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 6)
                            .background(Color(.systemGray6))
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }

            if isGeneratingSuggestion && suggestionText == nil {
                VStack(alignment: .leading, spacing: 8) {
                    Text("次はこうしませんか？")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.secondary)
                    HStack(spacing: 8) {
                        ProgressView()
                            .scaleEffect(0.9)
                        Text("提案を作成中...")
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                    }
                    .padding(12)
                    .background(AppTheme.accentBg)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            } else if let suggestionText {
                VStack(alignment: .leading, spacing: 8) {
                    Text("次はこうしませんか？")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.secondary)
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "lightbulb.fill")
                            .foregroundStyle(AppTheme.accent)
                        Text(suggestionText)
                            .font(.system(size: 14))
                            .lineSpacing(3)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(12)
                    .background(AppTheme.accentBg)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }

            // ステップカード
            if !recipe.steps.isEmpty {
                VStack(spacing: 0) {
                    HStack {
                        Text("STEP \(currentStep + 1) / \(recipe.steps.count)")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                    .padding(.bottom, 8)

                    Text(recipe.steps[currentStep])
                        .font(.system(size: 16))
                        .lineSpacing(5)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(16)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                    // 前へ / 次へ
                    HStack {
                        Button {
                            if currentStep > 0 { currentStep -= 1 }
                        } label: {
                            Label("前へ", systemImage: "chevron.left")
                                .font(.system(size: 14))
                                .foregroundStyle(currentStep == 0 ? .tertiary : .primary)
                        }
                        .disabled(currentStep == 0)

                        Spacer()

                        Button {
                            if currentStep < recipe.steps.count - 1 { currentStep += 1 }
                        } label: {
                            Label("次へ", systemImage: "chevron.right")
                                .font(.system(size: 14))
                                .labelStyle(.titleAndIcon)
                                .environment(\.layoutDirection, .rightToLeft)
                                .foregroundStyle(currentStep == recipe.steps.count - 1 ? .tertiary : .primary)
                        }
                        .disabled(currentStep == recipe.steps.count - 1)
                    }
                    .padding(.top, 12)
                }
                .padding(16)
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)

                VStack(alignment: .leading, spacing: 10) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showOverview.toggle()
                        }
                    } label: {
                        HStack {
                            Text("レシピ全体を見る")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(.secondary)
                            Spacer()
                            Image(systemName: showOverview ? "chevron.up" : "chevron.down")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .buttonStyle(.plain)

                    if showOverview {
                        ScrollView {
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(recipe.steps.indices, id: \.self) { i in
                                    Button {
                                        currentStep = i
                                    } label: {
                                        HStack(alignment: .top, spacing: 8) {
                                            Text("\(i + 1)")
                                                .font(.system(size: 11, weight: .bold))
                                                .foregroundStyle(i == currentStep ? .white : .secondary)
                                                .frame(width: 18, height: 18)
                                                .background(i == currentStep ? Color.primary : Color(.systemGray5))
                                                .clipShape(Circle())
                                            Text(recipe.steps[i])
                                                .font(.system(size: 13))
                                                .foregroundStyle(i == currentStep ? .primary : .secondary)
                                                .lineLimit(3)
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                        }
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 8)
                                        .background(i == currentStep ? Color(.systemGray6) : Color.clear)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .frame(maxHeight: 220)
                    }
                }
                .padding(.horizontal, 4)
            }

            Spacer()
        }
        .padding(24)
        .navigationTitle("タイマー")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("完成！") {
                    stopTimer()
                    navigateToLog = true
                }
                .bold()
                .foregroundStyle(.orange)
            }
        }
        .navigationDestination(isPresented: $navigateToLog) {
            CookingLogView(recipe: recipe, mood: mood)
        }
        .task(id: allLogs.count) {
            await generateSuggestion()
        }
        .onDisappear { stopTimer() }
    }

    private func toggleTimer() {
        if isRunning {
            stopTimer()
        } else {
            startTimer()
        }
    }

    private func startTimer() {
        isRunning = true
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            let total = recipe.cookingTime * 60
            if elapsedSeconds < total {
                elapsedSeconds += 1
            } else {
                stopTimer()
                navigateToLog = true
            }
        }
    }

    private func stopTimer() {
        isRunning = false
        timer?.invalidate()
        timer = nil
    }

    @MainActor
    private func generateSuggestion() async {
        let memos = allLogs
            .filter { $0.recipe?.id == recipe.id }
            .map { $0.memo.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .prefix(3)
            .map { $0 }

        guard !memos.isEmpty else {
            aiSuggestion = nil
            isGeneratingSuggestion = false
            return
        }

        isGeneratingSuggestion = true
        defer { isGeneratingSuggestion = false }
        do {
            aiSuggestion = try await gemini.generateMemoBasedSuggestion(
                recipeName: recipe.name,
                ingredients: recipe.ingredients,
                steps: recipe.steps,
                recentMemos: memos
            )
        } catch {
            aiSuggestion = nil
        }
    }
}
