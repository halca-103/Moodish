import UIKit
import FirebaseStorage

class StorageService {
    private let storage = Storage.storage()

    func uploadImage(_ image: UIImage, path: String) async throws -> String {
        guard let data = image.jpegData(compressionQuality: 0.7) else {
            throw StorageError.compressionFailed
        }

        let ref = storage.reference().child(path)
        _ = try await ref.putDataAsync(data)
        let url = try await ref.downloadURL()
        return url.absoluteString
    }

    func uploadRecipeImage(_ image: UIImage, recipeId: UUID) async throws -> String {
        try await uploadImage(image, path: "recipes/\(recipeId)/recipe.jpg")
    }

    func uploadDishImage(_ image: UIImage, recipeId: UUID) async throws -> String {
        try await uploadImage(image, path: "recipes/\(recipeId)/dish.jpg")
    }
}

enum StorageError: LocalizedError {
    case compressionFailed

    var errorDescription: String? { "画像の変換に失敗しました" }
}
