import SwiftUI

struct FolderPickerView: View {
    @EnvironmentObject var homeVM: HomeViewModel
    @Binding var selectedFolder: AppFolder?
    @Environment(\.dismiss) private var dismiss

    @State private var showNewFolderAlert = false
    @State private var newFolderName = ""

    var body: some View {
        NavigationStack {
            List {
                ForEach(homeVM.folders) { folder in
                    Button {
                        selectedFolder = folder
                        dismiss()
                    } label: {
                        HStack {
                            Image(systemName: "folder.fill")
                                .foregroundStyle(.blue)
                            Text(folder.name)
                                .foregroundStyle(.primary)
                            Spacer()
                            if selectedFolder?.id == folder.id {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.accentColor)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select Folder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        newFolderName = ""
                        showNewFolderAlert = true
                    } label: {
                        Image(systemName: "folder.badge.plus")
                    }
                }
            }
            .alert("New Folder", isPresented: $showNewFolderAlert) {
                TextField("Folder name", text: $newFolderName)
                Button("Create") {
                    homeVM.createFolder(name: newFolderName)
                }
                Button("Cancel", role: .cancel) {}
            }
            .onAppear {
                homeVM.loadFolders()
            }
        }
    }
}
