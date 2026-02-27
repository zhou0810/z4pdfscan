import SwiftUI

struct VMDetailView: View {
    let config: VMConfiguration
    @ObservedObject var appViewModel: AppViewModel
    @State private var showDisplay = true

    private var manager: VMManager? {
        appViewModel.vmManager(for: config.id)
    }

    private var currentState: String {
        appViewModel.vmState(for: config.id)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Control bar
            controlBar
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(.bar)

            Divider()

            // Display area
            if let manager = manager, manager.virtualMachine != nil {
                Picker("View", selection: $showDisplay) {
                    Text("Display").tag(true)
                    Text("Console").tag(false)
                }
                .pickerStyle(.segmented)
                .frame(width: 200)
                .padding(8)

                if showDisplay, let vm = manager.virtualMachine {
                    VMDisplayView(virtualMachine: vm)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    VMConsoleView(vmManager: manager)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            } else {
                vmInfoView
            }
        }
        .navigationTitle(config.name)
    }

    // MARK: - Control Bar

    private var controlBar: some View {
        HStack {
            Text(config.name)
                .font(.headline)

            Spacer()

            statusBadge

            if currentState == "stopped" || currentState == "error" {
                Button {
                    appViewModel.startVM(config.id)
                } label: {
                    Label("Start", systemImage: "play.fill")
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
            }

            if currentState == "running" {
                Button {
                    appViewModel.pauseVM(config.id)
                } label: {
                    Label("Pause", systemImage: "pause.fill")
                }

                Button {
                    appViewModel.stopVM(config.id)
                } label: {
                    Label("Stop", systemImage: "stop.fill")
                }
                .tint(.red)
            }

            if currentState == "paused" {
                Button {
                    appViewModel.resumeVM(config.id)
                } label: {
                    Label("Resume", systemImage: "play.fill")
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
            }

            Menu {
                Button("Force Stop", role: .destructive) {
                    appViewModel.forceStopVM(config.id)
                }
                Divider()
                Button("Delete VM", role: .destructive) {
                    appViewModel.deleteVM(config.id)
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
        }
    }

    private var statusBadge: some View {
        Text(currentState.capitalized)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(statusColor.opacity(0.2))
            .foregroundColor(statusColor)
            .clipShape(Capsule())
    }

    private var statusColor: Color {
        switch currentState {
        case "running": return .green
        case "paused": return .orange
        case "starting", "stopping": return .blue
        case "error": return .red
        default: return .gray
        }
    }

    // MARK: - Info View (when VM not running)

    private var vmInfoView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "desktopcomputer")
                .font(.system(size: 64))
                .foregroundColor(.secondary)

            Text(config.name)
                .font(.largeTitle)

            Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 8) {
                GridRow {
                    Text("CPU Cores:").foregroundColor(.secondary)
                    Text("\(config.cpuCount)")
                }
                GridRow {
                    Text("Memory:").foregroundColor(.secondary)
                    Text("\(config.memorySizeMB) MB")
                }
                GridRow {
                    Text("Disk:").foregroundColor(.secondary)
                    Text("\(config.diskSizeGB) GB")
                }
                GridRow {
                    Text("Display:").foregroundColor(.secondary)
                    Text("\(config.displayWidth) x \(config.displayHeight)")
                }
                if let iso = config.isoPath, !iso.isEmpty {
                    GridRow {
                        Text("ISO:").foregroundColor(.secondary)
                        Text(iso)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                }
                if let folder = config.sharedFolderPath, !folder.isEmpty {
                    GridRow {
                        Text("Shared:").foregroundColor(.secondary)
                        Text(folder)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                }
                GridRow {
                    Text("Created:").foregroundColor(.secondary)
                    Text(config.createdDate, style: .date)
                }
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
