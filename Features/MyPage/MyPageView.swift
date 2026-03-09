//
//  MyPageView.swift
//  TasteLog
//
//  Created by Fukushima Haruka on 2026/03/05.
//

import SwiftUI
import UIKit
import SwiftData

struct MyPageView: View {
    @Environment(HealthKitService.self) private var healthKit
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<Recipe> { $0.isDefaultSeed == true }) private var defaultRecipes: [Recipe]

    @State private var showAllergySettings = false
    @State private var showHowToUse = false
    @State private var showDeleteDefaultAlert = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button {
                        showHowToUse = true
                    } label: {
                        HStack(spacing: 14) {
                            Image(systemName: "questionmark.circle")
                                .font(.system(size: 16))
                                .foregroundStyle(.white)
                                .frame(width: 30, height: 30)
                                .background(AppTheme.accent)
                                .clipShape(RoundedRectangle(cornerRadius: 7))
                            VStack(alignment: .leading, spacing: 2) {
                                Text("使い方を確認")
                                    .font(.system(size: 15))
                                    .foregroundStyle(.primary)
                                Text("オンボーディング内容を見返す")
                                    .font(.system(size: 12))
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12))
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.vertical, 4)
                    }

                    Button {
                        showAllergySettings = true
                    } label: {
                        HStack(spacing: 14) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 16))
                                .foregroundStyle(.white)
                                .frame(width: 30, height: 30)
                                .background(Color.orange)
                                .clipShape(RoundedRectangle(cornerRadius: 7))
                            VStack(alignment: .leading, spacing: 2) {
                                Text("アレルギー・苦手食材")
                                    .font(.system(size: 15))
                                    .foregroundStyle(.primary)
                                Text("提案時に除外する食材を設定")
                                    .font(.system(size: 12))
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12))
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.vertical, 4)
                    }
                }

                Section("ヘルスケア連携") {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("睡眠時間を使って提案を最適化します")
                            .font(.system(size: 14, weight: .semibold))
                        Text(healthStatusText)
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 2)

                    Button {
                        Task { await healthKit.requestAuthorization() }
                    } label: {
                        Text("ヘルスケア連携を設定")
                    }

                    if healthKit.authorizationState == .denied {
                        Button {
                            openAppSettings()
                        } label: {
                            Text("設定アプリを開く")
                        }
                    }
                }

                if !defaultRecipes.isEmpty {
                    Section("デフォルトレシピ") {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("初回起動時に追加されたレシピ")
                                .font(.system(size: 14, weight: .semibold))
                            Text("\(defaultRecipes.count)件あります。不要なら一括削除できます")
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 2)

                        Button(role: .destructive) {
                            showDeleteDefaultAlert = true
                        } label: {
                            Text("デフォルトレシピを削除")
                        }
                    }
                }

                Section {
                    InfoRow(icon: "swift", color: .orange, title: "バージョン", value: "0.1.0")
                    InfoRow(icon: "server.rack", color: .blue, title: "データ保存", value: "ローカル")
                }
            }
            .navigationTitle("マイページ")
            .navigationDestination(isPresented: $showAllergySettings) {
                AllergySettingsView()
            }
            .navigationDestination(isPresented: $showHowToUse) {
                HowToUseView()
            }
            .alert("デフォルトレシピを削除しますか？", isPresented: $showDeleteDefaultAlert) {
                Button("削除", role: .destructive) {
                    try? DefaultRecipeSeeder.removeSeededRecipes(in: modelContext)
                }
                Button("キャンセル", role: .cancel) { }
            } message: {
                Text("この操作は取り消せません。")
            }
            .task {
                healthKit.refreshAuthorizationStatus()
            }
        }
    }

    private var healthStatusText: String {
        switch healthKit.authorizationState {
        case .notAvailable:
            return "このデバイスではヘルスケア連携を利用できません"
        case .notDetermined:
            return "未設定です。連携すると睡眠に合わせた提案が有効になります"
        case .denied:
            return "連携がオフです。設定アプリから許可してください"
        case .authorized:
            return "連携中です。睡眠データを提案に活用しています"
        }
    }

    private func openAppSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}

// MARK: - InfoRow
struct InfoRow: View {
    let icon: String
    let color: Color
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(.white)
                .frame(width: 30, height: 30)
                .background(color)
                .clipShape(RoundedRectangle(cornerRadius: 7))
            Text(title)
                .font(.system(size: 15))
            Spacer()
            Text(value)
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }
}
