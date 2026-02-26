import Foundation
import UIKit

enum ClaudeAPIError: LocalizedError {
    case noAPIKey
    case imageLoadFailed(Int)
    case requestFailed(String)
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .noAPIKey:
            return "No API key configured. Add your Claude API key in Settings."
        case .imageLoadFailed(let page):
            return "Failed to load image for page \(page + 1)."
        case .requestFailed(let message):
            return "API request failed: \(message)"
        case .invalidResponse:
            return "Could not parse the API response."
        }
    }
}

enum ClaudeAPIService {

    private static let endpoint = URL(string: "https://api.anthropic.com/v1/messages")!
    private static let model = "claude-sonnet-4-20250514"

    static func extractText(from pages: [ScannedPage], apiKey: String) async throws -> String {
        guard !apiKey.isEmpty else { throw ClaudeAPIError.noAPIKey }

        var contentParts: [[String: Any]] = []

        for (index, page) in pages.enumerated() {
            guard let imageData = try? Data(contentsOf: page.imageURL),
                  let image = UIImage(data: imageData),
                  let jpegData = image.jpegData(compressionQuality: 0.8) else {
                throw ClaudeAPIError.imageLoadFailed(index)
            }

            let base64String = jpegData.base64EncodedString()
            contentParts.append([
                "type": "image",
                "source": [
                    "type": "base64",
                    "media_type": "image/jpeg",
                    "data": base64String
                ]
            ])
        }

        contentParts.append([
            "type": "text",
            "text": "Extract all text from these document pages in order. Preserve the original formatting using Markdown (headings, lists, tables, bold, italic). Return only the extracted text."
        ])

        let body: [String: Any] = [
            "model": model,
            "max_tokens": 8192,
            "messages": [
                [
                    "role": "user",
                    "content": contentParts
                ]
            ]
        ]

        let jsonData = try JSONSerialization.data(withJSONObject: body)

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.httpBody = jsonData

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ClaudeAPIError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            if let errorJSON = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let errorInfo = errorJSON["error"] as? [String: Any],
               let message = errorInfo["message"] as? String {
                throw ClaudeAPIError.requestFailed(message)
            }
            throw ClaudeAPIError.requestFailed("HTTP \(httpResponse.statusCode)")
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let content = json["content"] as? [[String: Any]],
              let firstBlock = content.first,
              let text = firstBlock["text"] as? String else {
            throw ClaudeAPIError.invalidResponse
        }

        return text
    }
}
