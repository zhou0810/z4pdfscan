import SwiftUI

struct ContentView: View {
    @ObservedObject var appViewModel: AppViewModel
    @StateObject private var createVM = CreateVMViewModel()

    var body: some View {
        NavigationSplitView {
            SidebarView(appViewModel: appViewModel)
        } detail: {
            if let selectedId = appViewModel.selectedVMId,
               let config = appViewModel.vmConfigs.first(where: { $0.id == selectedId }) {
                VMDetailView(config: config, appViewModel: appViewModel)
            } else {
                Text("Select or create a virtual machine")
                    .font(.title2)
                    .foregroundColor(.secondary)
            }
        }
        .sheet(isPresented: $appViewModel.showCreateSheet) {
            CreateVMSheet(
                viewModel: createVM,
                onCreate: {
                    appViewModel.createVM(from: createVM)
                    appViewModel.showCreateSheet = false
                    resetCreateVM()
                },
                onCancel: {
                    appViewModel.showCreateSheet = false
                    resetCreateVM()
                }
            )
        }
        .alert("Error", isPresented: $appViewModel.showError) {
            Button("OK") {}
        } message: {
            Text(appViewModel.errorMessage ?? "Unknown error")
        }
        .frame(minWidth: 800, minHeight: 500)
    }

    private func resetCreateVM() {
        // Reset for next time
        createVM.name = ""
        createVM.cpuCount = 2
        createVM.memorySizeMB = 4096
        createVM.diskSizeGB = 64
        createVM.displayWidth = 1920
        createVM.displayHeight = 1080
        createVM.isoPath = ""
        createVM.sharedFolderPath = ""
    }
}
