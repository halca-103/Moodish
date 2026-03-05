//
//  RecipeRegistration.swift
//  TasteLog
//
//  Created by Fukushima Haruka on 2026/03/04.
//

import SwiftUI

struct RegistrationMethodView: View {
    @State private var showImagePicker = false
    @State private var showManualInput = false
    @State private var showURLInput   = false
    @State private var imageSource: UIImagePickerController.SourceType = .photoLibrary
    @State private var showActionSheet = false
    @State private var selectedImage: UIImage? = nil
    @State private var navigateToAnalyzing = false
    @State private var showCameraActionSheet = false

    var body: some View {
        NavigationStack {
            List {
                // 画像から登録
//                Button {
//                    showActionSheet = true
//                } label: {
//                    MethodRow(
//                        icon: "camera",
//                        title: "画像から登録",
//                        description: "AIが自動でレシピを読み取る",
//                        isHighlighted: true
//                    )
//                }
                Button {
                    showCameraActionSheet = true
                } label: {
                    MethodRow(
                        icon: "camera",
                        title: "画像から登録",
                        description: "AIが自動でレシピを読み取る",
                        isHighlighted: true
                    )
                }

                // URLから登録
                Button {
                    showURLInput = true
                } label: {
                    MethodRow(
                        icon: "link",
                        title: "URLから登録",
                        description: "クックパッド等のURLを貼る"
                    )
                }

                // 手打ちで登録
                Button {
                    showManualInput = true
                } label: {
                    MethodRow(
                        icon: "pencil",
                        title: "手打ちで登録",
                        description: "料理名・材料・手順を入力"
                    )
                }
            }
            .navigationTitle("まずはレシピを登録")
            .navigationBarTitleDisplayMode(.inline)
            // カメラ / ライブラリ選択
//            .confirmationDialog("レシピの写真を選んでください", isPresented: $showActionSheet, titleVisibility: .visible) {
//                Button("カメラで撮影") {
//                    imageSource = .camera
//                    showImagePicker = true
//                }
//                Button("ライブラリから選ぶ") {
//                    imageSource = .photoLibrary
//                    showImagePicker = true
//                }
//                Button("キャンセル", role: .cancel) {}
//            }
            .sheet(isPresented: $showCameraActionSheet) {
                CameraActionSheetView(
                    onCamera: {
                        showCameraActionSheet = false
                        imageSource = .camera
                        showImagePicker = true
                    },
                    onLibrary: {
                        showCameraActionSheet = false
                        imageSource = .photoLibrary
                        showImagePicker = true
                    },
                    onCancel: {
                        showCameraActionSheet = false
                    }
                )
                .presentationDetents([.height(220)])
                //.presentationDetents([.medium])
            }
            // 手打ち入力へ遷移
            .navigationDestination(isPresented: $showManualInput) {
                ManualInputView()
            }
            // URL入力へ遷移（P2-11で実装）
            .navigationDestination(isPresented: $showURLInput) {
                Text("URL登録（近日実装）")
            }
            // 画像選択へ遷移（P2-02で実装）
            .sheet(isPresented: $showImagePicker) {
                ImagePickerView(sourceType: imageSource, selectedImage: $selectedImage)
            }
            .onChange(of: selectedImage) { _, image in
                guard image != nil else { return }
                showImagePicker = false
                navigateToAnalyzing = true
            }
            
            .navigationDestination(isPresented: $navigateToAnalyzing) {
                if let image = selectedImage {
                    AnalyzingView(image: image)
                }
            }

        }
    }
}

// MARK: - MethodRow
private struct MethodRow: View {
    let icon: String
    let title: String
    let description: String
    var isHighlighted: Bool = false

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(isHighlighted ? .white : .primary)
                .frame(width: 36, height: 36)
                .background(isHighlighted ? Color.primary : Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.primary)
                Text(description)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    RegistrationMethodView()
}
