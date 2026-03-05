//
//  TimerView.swift
//  TasteLog
//
//  Created by Fukushima Haruka on 2026/03/05.
//
import SwiftUI

struct TimerView: View {
    let recipe: Recipe
    let mood: Mood

    @State private var timeRemaining: Int
    @State private var isRunning = false
    @State private var currentStep = 0
    @State private var navigateToLog = false
    @State private var timer: Timer? = nil

    init(recipe: Recipe, mood: Mood) {
        self.recipe = recipe
        self.mood = mood
        _timeRemaining = State(initialValue: recipe.cookingTime * 60)
    }

    var formattedTime: String {
        let m = timeRemaining / 60
        let s = timeRemaining % 60
        return String(format: "%02d:%02d", m, s)
    }

    var progress: Double {
        let total = recipe.cookingTime * 60
        guard total > 0 else { return 0 }
        return 1.0 - Double(timeRemaining) / Double(total)
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
            if timeRemaining > 0 {
                timeRemaining -= 1
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
}
