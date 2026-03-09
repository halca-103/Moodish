//
//  OnboardingView.swift
//  TasteLog
//
//  Created by Fukushima Haruka on 2026/03/05.
//

import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("selectedTab") private var selectedTab = 0
    @State private var currentPage = 0
    @State private var showRegistration = false

    let pages: [OnboardingPage] = [
        OnboardingPage(
            emoji: "😊",
            title: "今日の気分から\n料理を選ぼう",
            description: "体調・気分を選ぶだけで\nあなたに合った料理を提案します"
        ),
        OnboardingPage(
            emoji: "📖",
            title: "作った料理を\n記録しよう",
            description: "記録が増えるほど\n提案の精度が上がっていきます"
        ),
        OnboardingPage(
            emoji: "✨",
            title: "あの日の美味しかったを\n今日の一品に",
            description: "まず最初のレシピを\n登録してみましょう"
        ),
    ]

    var body: some View {
        if showRegistration {
            NavigationStack {
                RegistrationMethodView(onComplete: {
                    selectedTab = 1
                    hasCompletedOnboarding = true
                })
            }
        } else {
            VStack(spacing: 0) {
                Spacer()

                // ページコンテンツ
                TabView(selection: $currentPage) {
                    ForEach(pages.indices, id: \.self) { i in
                        VStack(spacing: 24) {
                            Text(pages[i].emoji)
                                .font(.system(size: 80))
                            Text(pages[i].title)
                                .font(.system(size: 26, weight: .bold))
                                .multilineTextAlignment(.center)
                                .lineSpacing(4)
                            Text(pages[i].description)
                                .font(.system(size: 15))
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .lineSpacing(4)
                        }
                        .padding(.horizontal, 40)
                        .tag(i)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(height: 320)

                // ページインジケーター
                HStack(spacing: 8) {
                    ForEach(pages.indices, id: \.self) { i in
                        Capsule()
                            .fill(i == currentPage ? Color.primary : Color(.systemGray4))
                            .frame(width: i == currentPage ? 20 : 8, height: 8)
                            .animation(.easeInOut(duration: 0.2), value: currentPage)
                    }
                }
                .padding(.top, 24)

                Spacer()

                // ボタン
                VStack(spacing: 12) {
                    if currentPage < pages.count - 1 {
                        Button {
                            withAnimation { currentPage += 1 }
                        } label: {
                            Text("次へ")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.primary)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }

                        Button {
                            hasCompletedOnboarding = true
                        } label: {
                            Text("スキップ")
                                .font(.system(size: 14))
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        Button {
                            showRegistration = true
                        } label: {
                            Text("最初のレシピを登録する")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.primary)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }

                        Button {
                            hasCompletedOnboarding = true
                        } label: {
                            Text("あとで登録する")
                                .font(.system(size: 14))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
            }
        }
    }
}

struct OnboardingPage {
    let emoji: String
    let title: String
    let description: String
}
