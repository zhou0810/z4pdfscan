import SwiftUI

struct SettingsView: View {
    @StateObject private var settingsVM = SettingsViewModel()

    var body: some View {
        Form {
            Section {
                SecureField("Claude API Key", text: $settingsVM.apiKey)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            } header: {
                Text("Claude API Key")
            } footer: {
                Text("Used for AI text extraction from scanned documents. Your key is stored locally on this device.")
            }

            Section {
                Button("Clear API Key", role: .destructive) {
                    settingsVM.clearAPIKey()
                }
                .disabled(!settingsVM.isAPIKeySet)
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}
