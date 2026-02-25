import Foundation
import Combine

class HomeViewModel: ObservableObject {
    @Published var folders: [AppFolder] = []

    func loadFolders() {
        folders = FileManagerService.listFolders()
    }

    func createFolder(name: String) {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        if let folder = FileManagerService.createFolder(name: name) {
            folders.insert(folder, at: 0)
        }
    }

    func deleteFolder(at offsets: IndexSet) {
        let foldersToDelete = offsets.map { folders[$0] }
        for folder in foldersToDelete {
            FileManagerService.deleteFolder(at: folder.url)
        }
        folders.remove(atOffsets: offsets)
    }
}
