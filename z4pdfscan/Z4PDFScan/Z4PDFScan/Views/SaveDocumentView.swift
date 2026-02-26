import SwiftUI

struct SaveDocumentView: View {
    @ObservedObject var scannerVM: ScannerViewModel
    @StateObject private var saveVM = SaveViewModel()
    @EnvironmentObject var homeVM: HomeViewModel

    @Environment(\.dismiss) private var dismiss
    @State private var showFolderPicker = false
    @State private var showExportPicker = false
    @State private var showSavedAlert = false
    @State private var showErrorAlert = false

    private var isAPIKeySet: Bool {
        !SettingsViewModel.storedAPIKey().isEmpty
    }

    var body: some View {
        Form {
            Section("Document Name") {
                TextField("Name", text: $saveVM.documentName)
                    .textInputAutocapitalization(.words)
            }

            Section {
                Toggle("AI Text PDF", isOn: $saveVM.useClaudeOCR)
                    .disabled(!isAPIKeySet)
                if !isAPIKeySet {
                    Text("Add your Claude API key in Settings to enable.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if !saveVM.processingStatus.isEmpty {
                    HStack(spacing: 8) {
                        ProgressView()
                        Text(saveVM.processingStatus)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            } header: {
                Text("AI Text Extraction")
            } footer: {
                if isAPIKeySet {
                    Text("Uses Claude to extract text and generate a selectable-text PDF.")
                }
            }

            if !saveVM.useClaudeOCR {
                Section("Resolution") {
                    Picker("Quality", selection: $saveVM.selectedResolution) {
                        ForEach(ResolutionOption.allCases) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }

            Section("Destination Folder") {
                Button {
                    showFolderPicker = true
                } label: {
                    HStack {
                        Image(systemName: "folder.fill")
                            .foregroundStyle(.blue)
                        if let folder = saveVM.selectedFolder {
                            Text(folder.name)
                                .foregroundStyle(.primary)
                        } else {
                            Text("Select a folder")
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section {
                Button {
                    if saveVM.useClaudeOCR {
                        saveVM.saveWithOCR(pages: scannerVM.pages)
                    } else {
                        saveVM.save(pages: scannerVM.pages)
                    }
                } label: {
                    HStack {
                        Spacer()
                        if saveVM.isSaving {
                            ProgressView()
                                .padding(.trailing, 8)
                        }
                        Text("Save to App")
                            .fontWeight(.semibold)
                        Spacer()
                    }
                }
                .disabled(saveVM.selectedFolder == nil || saveVM.isSaving || saveVM.documentName.isEmpty)

                Button {
                    if saveVM.useClaudeOCR {
                        saveVM.exportWithOCR(pages: scannerVM.pages)
                    } else {
                        saveVM.generateExportPDF(pages: scannerVM.pages)
                    }
                } label: {
                    HStack {
                        Spacer()
                        Text("Export to Files")
                        Spacer()
                    }
                }
                .disabled(saveVM.isSaving || saveVM.documentName.isEmpty)
            }

            Section {
                Text("\(scannerVM.pages.count) page(s)")
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Save Document")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if saveVM.selectedFolder == nil {
                let folders = FileManagerService.listFolders()
                if folders.isEmpty {
                    saveVM.selectedFolder = FileManagerService.createFolder(name: "Default")
                } else {
                    saveVM.selectedFolder = folders.first
                }
            }
        }
        .sheet(isPresented: $showFolderPicker) {
            FolderPickerView(selectedFolder: $saveVM.selectedFolder)
        }
        .sheet(isPresented: $showExportPicker) {
            if let url = saveVM.exportURL {
                DocumentExportView(url: url) {
                    showExportPicker = false
                }
            }
        }
        .onChange(of: saveVM.savedURL) { newValue in
            if newValue != nil {
                showSavedAlert = true
            }
        }
        .onChange(of: saveVM.exportURL) { newValue in
            if newValue != nil {
                showExportPicker = true
            }
        }
        .alert("Saved", isPresented: $showSavedAlert) {
            Button("OK") {
                scannerVM.clearAll()
                dismiss()
            }
        } message: {
            Text("Document saved successfully.")
        }
        .onChange(of: saveVM.ocrError) { newValue in
            if newValue != nil {
                showErrorAlert = true
            }
        }
        .alert("Error", isPresented: $showErrorAlert) {
            Button("OK") {
                saveVM.ocrError = nil
            }
        } message: {
            Text(saveVM.ocrError ?? "An unknown error occurred.")
        }
    }
}
