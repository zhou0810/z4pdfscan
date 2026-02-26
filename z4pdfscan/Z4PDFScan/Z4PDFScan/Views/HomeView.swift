import SwiftUI

struct HomeView: View {
    @StateObject private var homeVM = HomeViewModel()
    @StateObject private var scannerVM = ScannerViewModel()

    @State private var showScanner = false
    @State private var showNewFolderAlert = false
    @State private var newFolderName = ""
    @State private var navigateToPreview = false

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                List {
                    if homeVM.folders.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "folder")
                                .font(.largeTitle)
                                .foregroundStyle(.secondary)
                            Text("No Folders")
                                .font(.title3)
                                .fontWeight(.semibold)
                            Text("Tap + to create a folder, then scan your documents.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 60)
                        .listRowBackground(Color.clear)
                    } else {
                        ForEach(homeVM.folders) { folder in
                            NavigationLink(value: folder) {
                                HStack {
                                    Image(systemName: "folder.fill")
                                        .foregroundStyle(.blue)
                                    VStack(alignment: .leading) {
                                        Text(folder.name)
                                            .font(.headline)
                                        Text(folder.createdDate, style: .date)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                        .onDelete(perform: homeVM.deleteFolder)
                    }
                }
                .navigationTitle("Z4PDFScan")
                .navigationDestination(for: AppFolder.self) { folder in
                    FolderDetailView(folder: folder)
                }
                .toolbar {
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

                // Scan FAB
                Button {
                    showScanner = true
                } label: {
                    Image(systemName: "doc.viewfinder")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .frame(width: 60, height: 60)
                        .background(Color.accentColor)
                        .clipShape(Circle())
                        .shadow(radius: 4)
                }
                .padding(24)
            }
            .sheet(isPresented: $showScanner) {
                DocumentCameraView(
                    onScanCompleted: { images in
                        showScanner = false
                        scannerVM.addScannedImages(images)
                        navigateToPreview = true
                    },
                    onCancelled: {
                        showScanner = false
                    }
                )
            }
            .navigationDestination(isPresented: $navigateToPreview) {
                PagePreviewView(scannerVM: scannerVM)
            }
            .onAppear {
                homeVM.loadFolders()
            }
        }
        .environmentObject(homeVM)
    }
}

extension AppFolder: Hashable {
    static func == (lhs: AppFolder, rhs: AppFolder) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
