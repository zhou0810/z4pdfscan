import Foundation

class SettingsViewModel: ObservableObject {

    private static let apiKeyKey = "claude_api_key"

    @Published var apiKey: String {
        didSet {
            UserDefaults.standard.set(apiKey, forKey: Self.apiKeyKey)
        }
    }

    var isAPIKeySet: Bool {
        !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    init() {
        self.apiKey = UserDefaults.standard.string(forKey: Self.apiKeyKey) ?? ""
    }

    func clearAPIKey() {
        apiKey = ""
        UserDefaults.standard.removeObject(forKey: Self.apiKeyKey)
    }

    static func storedAPIKey() -> String {
        UserDefaults.standard.string(forKey: apiKeyKey) ?? ""
    }
}
