import SwiftUI

struct SidebarView: View {
    @ObservedObject var appViewModel: AppViewModel

    var body: some View {
        List(selection: $appViewModel.selectedVMId) {
            ForEach(appViewModel.vmConfigs) { config in
                HStack {
                    statusIcon(for: config.id)
                    VStack(alignment: .leading) {
                        Text(config.name)
                            .font(.headline)
                        Text("\(config.cpuCount) CPU, \(config.memorySizeMB) MB RAM")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .tag(config.id)
                .contextMenu {
                    Button("Delete", role: .destructive) {
                        appViewModel.deleteVM(config.id)
                    }
                }
            }
        }
        .listStyle(.sidebar)
        .toolbar {
            ToolbarItem {
                Button {
                    appViewModel.showCreateSheet = true
                } label: {
                    Label("New VM", systemImage: "plus")
                }
            }
        }
    }

    @ViewBuilder
    private func statusIcon(for id: UUID) -> some View {
        let state = appViewModel.vmState(for: id)
        switch state {
        case "running":
            Image(systemName: "circle.fill")
                .foregroundColor(.green)
                .font(.caption)
        case "paused":
            Image(systemName: "circle.fill")
                .foregroundColor(.orange)
                .font(.caption)
        case "starting", "stopping":
            ProgressView()
                .controlSize(.small)
        default:
            Image(systemName: "circle.fill")
                .foregroundColor(.gray)
                .font(.caption)
        }
    }
}
