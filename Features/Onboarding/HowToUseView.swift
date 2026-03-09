import SwiftUI

struct HowToUseView: View {
    private let pages: [OnboardingPage] = [
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
            description: "最初のレシピ登録後も\nマイページからいつでも確認できます"
        )
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                ForEach(pages.indices, id: \.self) { i in
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 10) {
                            Text(pages[i].emoji)
                                .font(.system(size: 28))
                            Text("STEP \(i + 1)")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(.secondary)
                        }

                        Text(pages[i].title)
                            .font(.system(size: 20, weight: .bold))
                            .lineSpacing(3)
                        Text(pages[i].description)
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                            .lineSpacing(3)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }
            .padding(20)
        }
        .navigationTitle("使い方")
        .navigationBarTitleDisplayMode(.inline)
    }
}
