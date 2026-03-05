//
//  FilterView.swift
//  TasteLog
//
//  Created by Fukushima Haruka on 2026/03/05.
//

import SwiftUI

struct FilterView: View {
    let mood: Mood

    @State private var selectedWeight: Weight = .normal
    @State private var ingredientInput: String = ""
    @State private var selectedIngredients: [String] = []
    @State private var navigateToSuggestion = false
    
    @State private var selectedFlavors: Set<String> = []


    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {

                // 重さ
                VStack(alignment: .leading, spacing: 10) {
                    Text("重さ")
                        .font(.system(size: 15, weight: .semibold))
                    HStack(spacing: 10) {
                        ForEach(Weight.allCases) { w in
                            ChipButton(
                                label: "\(w.emoji) \(w.rawValue)",
                                isSelected: selectedWeight == w
                            ) {
                                selectedWeight = w
                            }
                        }
                    }
                }
                VStack(alignment: .leading, spacing: 10) {
                    Text("味・性質")
                        .font(.system(size: 15, weight: .semibold))
                    FlowLayout(spacing: 8) {
                        ForEach(["さっぱり", "こってり", "温かい", "冷たい", "辛い", "甘い"], id: \.self) { flavor in
                            ChipButton(
                                label: flavor,
                                isSelected: selectedFlavors.contains(flavor)
                            ) {
                                if selectedFlavors.contains(flavor) {
                                    selectedFlavors.remove(flavor)
                                } else {
                                    selectedFlavors.insert(flavor)
                                }
                            }
                        }
                    }
                }


                // 使いたい食材
                VStack(alignment: .leading, spacing: 10) {
                    Text("使いたい食材")
                        .font(.system(size: 15, weight: .semibold))
                    Text("任意")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)

                    HStack {
                        TextField("例：鶏肉、玉ねぎ", text: $ingredientInput)
                            .textFieldStyle(.roundedBorder)
                        Button {
                            let trimmed = ingredientInput.trimmingCharacters(in: .whitespaces)
                            if !trimmed.isEmpty {
                                selectedIngredients.append(trimmed)
                                ingredientInput = ""
                            }
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 24))
                                .foregroundStyle(.primary)
                        }
                    }

                    if !selectedIngredients.isEmpty {
                        FlowLayout(spacing: 8) {
                            ForEach(selectedIngredients, id: \.self) { ing in
                                HStack(spacing: 4) {
                                    Text(ing)
                                        .font(.system(size: 13))
                                    Button {
                                        selectedIngredients.removeAll { $0 == ing }
                                    } label: {
                                        Image(systemName: "xmark")
                                            .font(.system(size: 10, weight: .bold))
                                    }
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.primary)
                                .foregroundStyle(Color(.systemBackground))
                                .clipShape(Capsule())
                            }
                        }
                    }
                }

                Button {
                    navigateToSuggestion = true
                } label: {
                    Text("提案を見る")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(20)
        }
        .navigationTitle("どんな料理にする？")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $navigateToSuggestion) {
            SuggestionView(mood: mood, weight: selectedWeight, ingredients: selectedIngredients)
        }
    }
}

// MARK: - ChipButton
struct ChipButton: View {
    let label: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(label)
                .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(isSelected ? Color.primary : Color(.systemGray6))
                .foregroundStyle(isSelected ? Color(.systemBackground) : Color.primary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
}

// MARK: - FlowLayout
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        let height = rows.map { $0.map { $0.sizeThatFits(.unspecified).height }.max() ?? 0 }.reduce(0) { $0 + $1 + spacing }
        return CGSize(width: proposal.width ?? 0, height: max(0, height - spacing))
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        var y = bounds.minY
        for row in rows {
            var x = bounds.minX
            let rowHeight = row.map { $0.sizeThatFits(.unspecified).height }.max() ?? 0
            for subview in row {
                let size = subview.sizeThatFits(.unspecified)
                subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
                x += size.width + spacing
            }
            y += rowHeight + spacing
        }
    }

    private func computeRows(proposal: ProposedViewSize, subviews: Subviews) -> [[LayoutSubview]] {
        var rows: [[LayoutSubview]] = [[]]
        var currentWidth: CGFloat = 0
        let maxWidth = proposal.width ?? 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentWidth + size.width > maxWidth && !rows[rows.count - 1].isEmpty {
                rows.append([])
                currentWidth = 0
            }
            rows[rows.count - 1].append(subview)
            currentWidth += size.width + spacing
        }
        return rows
    }
}
