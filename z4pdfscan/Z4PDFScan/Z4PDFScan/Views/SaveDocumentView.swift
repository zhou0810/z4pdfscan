import SwiftUI

struct SaveDocumentView: View {
    @ObservedObject var scannerVM: ScannerViewModel
    @StateObject private var saveVM = SaveViewModel()
    @EnvironmentObject var homeVM: HomeViewModel

    @Environment(\.dismiss) private var dismiss
    @State private var showFolderPicker = false
    @State private var showExportPicker = false
    @State private var showSavedAlert = false

    var body: some View {
        Form {
            Section("Document Name") {
                TextField("Name", text: $saveVM.documentName)
                    .textInputAutocapitalization(.words)
            }

            Section("Resolution") {
                Picker("Quality", selection: $saveVM.selectedResolution) {
                    ForEach(ResolutionOption.allCases) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
                .pickerStyle(.segmented)
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
                    saveVM.save(pages: scannerVM.pages)
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
                    saveVM.generateExportPDF(pages: scannerVM.pages)
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
    }
}
