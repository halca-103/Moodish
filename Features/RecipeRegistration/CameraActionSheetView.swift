//
//  CameraActionSheetView.swift
//  TasteLog
//
//  Created by Fukushima Haruka on 2026/03/05.
//

import SwiftUI

struct CameraActionSheetView: View {
    let onCamera: () -> Void
    let onLibrary: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // タイトル
            Text("レシピの写真を選んでください")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
                .padding(.vertical, 14)

            Divider()

            // カメラ
            Button {
                onCamera()
            } label: {
                HStack(spacing: 14) {
                    Image(systemName: "camera")
                        .font(.system(size: 18))
                    Text("カメラで撮影")
                        .font(.system(size: 17))
                }
                .foregroundStyle(.blue)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
            }

            Divider()

            // ライブラリ
            Button {
                onLibrary()
            } label: {
                HStack(spacing: 14) {
                    Image(systemName: "photo.on.rectangle")
                        .font(.system(size: 18))
                    Text("ライブラリから選ぶ")
                        .font(.system(size: 17))
                }
                .foregroundStyle(.blue)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
            }

            Divider()

            // キャンセル
            Button {
                onCancel()
            } label: {
                Text("キャンセル")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            }
        }
        .background(Color(.systemBackground))
    }
}
