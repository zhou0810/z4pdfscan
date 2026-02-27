import SwiftUI

@MainActor
final class CreateVMViewModel: ObservableObject {
    @Published var name: String = ""
    @Published var cpuCount: Int = 2
    @Published var memorySizeMB: Int = 4096
    @Published var diskSizeGB: Int = 64
    @Published var displayWidth: Int = 1920
    @Published var displayHeight: Int = 1080
    @Published var isoPath: String = ""
    @Published var sharedFolderPath: String = ""

    let maxCPU: Int = ProcessInfo.processInfo.processorCount
    let maxMemoryMB: Int = Int(ProcessInfo.processInfo.physicalMemory / (1024 * 1024))

    static let resolutions: [(String, Int, Int)] = [
        ("1280 x 720 (HD)", 1280, 720),
        ("1920 x 1080 (Full HD)", 1920, 1080),
        ("2560 x 1440 (QHD)", 2560, 1440),
        ("3840 x 2160 (4K)", 3840, 2160),
    ]

    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
            && cpuCount >= 1
            && memorySizeMB >= 512
            && diskSizeGB >= 1
    }

    func browseISO() {
        let panel = NSOpenPanel()
        panel.title = "Select Linux ISO"
        panel.allowedContentTypes = [.init(filenameExtension: "iso")!]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        if panel.runModal() == .OK, let url = panel.url {
            isoPath = url.path
        }
    }

    func browseSharedFolder() {
        let panel = NSOpenPanel()
        panel.title = "Select Shared Folder"
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        if panel.runModal() == .OK, let url = panel.url {
            sharedFolderPath = url.path
        }
    }

    func buildConfig() -> VMConfiguration {
        VMConfiguration(
            name: name.trimmingCharacters(in: .whitespaces),
            cpuCount: cpuCount,
            memorySizeMB: memorySizeMB,
            diskSizeGB: diskSizeGB,
            isoPath: isoPath.isEmpty ? nil : isoPath,
            displayWidth: displayWidth,
            displayHeight: displayHeight,
            sharedFolderPath: sharedFolderPath.isEmpty ? nil : sharedFolderPath
        )
    }
}
