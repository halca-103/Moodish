//
//  AllergySettingsView.swift
//  TasteLog
//
//  Created by Fukushima Haruka on 2026/03/05.
//

import SwiftUI

struct AllergySettingsView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var profile = AllergyProfile.load()
    @State private var newAllergy = ""
    @State private var newDislike = ""

    var body: some View {
        List {
            // アレルギー
            Section {
                FlowSection(
                    items: $profile.allergies,
                    presets: AllergyProfile.defaultAllergies,
                    newItemText: $newAllergy,
                    placeholder: "追加（例：小麦）"
                )
            } header: {
                Text("アレルギー")
            } footer: {
                Text("提案時にこれらの食材を含むレシピを除外します")
                    .font(.system(size: 11))
            }

            // 苦手食材
            Section {
                FlowSection(
                    items: $profile.dislikes,
                    presets: [],
                    newItemText: $newDislike,
                    placeholder: "追加（例：玉ねぎ）"
                )
            } header: {
                Text("苦手食材（任意）")
            }

            // 注意書き
            Section {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "exclamationmark.circle")
                        .foregroundStyle(.orange)
                    Text("この設定は提案の参考情報です。必ず食材ラベルをご確認ください。")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("アレルギー・苦手食材")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("保存") {
                    profile.save()
                    dismiss()
                }
                .bold()
            }
        }
    }
}

// MARK: - FlowSection
struct FlowSection: View {
    @Binding var items: [String]
    let presets: [String]
    @Binding var newItemText: String
    let placeholder: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // プリセットチップ
            if !presets.isEmpty {
                FlowLayout(spacing: 8) {
                    ForEach(presets, id: \.self) { preset in
                        let isSelected = items.contains(preset)
                        Button {
                            if isSelected {
                                items.removeAll { $0 == preset }
                            } else {
                                items.append(preset)
                            }
                        } label: {
                            Text(preset)
                                .font(.system(size: 13))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(isSelected ? Color.primary : Color(.systemGray6))
                                .foregroundStyle(isSelected ? Color(.systemBackground) : Color.primary)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                        .animation(.easeInOut(duration: 0.15), value: isSelected)
                    }
                }
            }

            // カスタム追加済みアイテム
            let customItems = items.filter { !presets.contains($0) }
            if !customItems.isEmpty {
                FlowLayout(spacing: 8) {
                    ForEach(customItems, id: \.self) { item in
                        HStack(spacing: 4) {
                            Text(item)
                                .font(.system(size: 13))
                            Button {
                                items.removeAll { $0 == item }
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

            // テキスト入力
            HStack {
                TextField(placeholder, text: $newItemText)
                    .textFieldStyle(.roundedBorder)
                Button {
                    let trimmed = newItemText.trimmingCharacters(in: .whitespaces)
                    if !trimmed.isEmpty && !items.contains(trimmed) {
                        items.append(trimmed)
                        newItemText = ""
                    }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(.primary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}
