//
//  MyPageView.swift
//  TasteLog
//
//  Created by Fukushima Haruka on 2026/03/05.
//

import SwiftUI

struct MyPageView: View {
    @State private var showAllergySettings = false

    var body: some View {
        NavigationStack {
            List {
                Section {
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

                Section {
                    InfoRow(icon: "swift", color: .orange, title: "バージョン", value: "0.1.0")
                    InfoRow(icon: "server.rack", color: .blue, title: "データ保存", value: "ローカル")
                }
            }
            .navigationTitle("マイページ")
            .navigationDestination(isPresented: $showAllergySettings) {
                AllergySettingsView()
            }
        }
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
