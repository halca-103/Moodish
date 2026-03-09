import Foundation

enum UserFacingError {
    static func message(for error: Error, fallback: String) -> String {
        if let gemini = error as? GeminiError {
            return gemini.errorDescription ?? fallback
        }
        if let storage = error as? StorageError {
            return storage.errorDescription ?? fallback
        }
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet, .networkConnectionLost:
                return "通信が不安定です。ネットワーク接続を確認して再度お試しください。"
            case .timedOut:
                return "通信がタイムアウトしました。時間をおいて再度お試しください。"
            case .badURL:
                return "URLの形式が正しくありません。入力内容を確認してください。"
            case .cannotFindHost, .cannotConnectToHost, .dnsLookupFailed:
                return "接続先にアクセスできませんでした。URLまたは通信環境を確認してください。"
            default:
                return "通信エラーが発生しました。時間をおいて再度お試しください。"
            }
        }
        if error is DecodingError {
            return "解析結果の読み取りに失敗しました。別の画像やURLでお試しください。"
        }

        // GoogleGenerativeAI のエラーはユーザー向けに日本語で要約する
        let debugDescription = String(describing: error)
        if debugDescription.contains("GenerateContentError") {
            return "AI解析でエラーが発生しました。Gemini APIの利用上限または一時障害の可能性があります。時間をおいて再度お試しください。"
        }

        return fallback
    }
}
