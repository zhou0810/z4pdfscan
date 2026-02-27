import Foundation
import Virtualization

/// Manages the lifecycle of a single virtual machine.
@MainActor
final class VMManager: NSObject, ObservableObject {

    // MARK: - Published state

    @Published private(set) var state: VZVirtualMachine.State = .stopped
    @Published var consoleOutput: String = ""

    // MARK: - Properties

    let config: VMConfiguration
    private(set) var virtualMachine: VZVirtualMachine?

    private let store = VMConfigStore.shared
    private var stateObservation: NSKeyValueObservation?

    // Serial console pipe
    private var serialReadPipe: Pipe?
    private var serialWritePipe: Pipe?

    init(config: VMConfiguration) {
        self.config = config
        super.init()
    }

    // MARK: - Build VM Configuration

    func buildConfiguration() throws -> VZVirtualMachineConfiguration {
        let vzConfig = VZVirtualMachineConfiguration()

        // CPU & Memory
        vzConfig.cpuCount = config.cpuCount
        vzConfig.memorySize = UInt64(config.memorySizeMB) * 1024 * 1024

        // Boot loader — EFI
        let efiVarsPath = store.efiVariableStorePath(for: config.id)
        let efiVariableStore: VZEFIVariableStore
        if FileManager.default.fileExists(atPath: efiVarsPath.path) {
            efiVariableStore = VZEFIVariableStore(url: efiVarsPath)
        } else {
            efiVariableStore = try VZEFIVariableStore(creatingVariableStoreAt: efiVarsPath)
        }
        let bootLoader = VZEFIBootLoader()
        bootLoader.variableStore = efiVariableStore
        vzConfig.bootLoader = bootLoader

        // Graphics — Virtio GPU
        let graphicsDevice = VZVirtioGraphicsDeviceConfiguration()
        let scanout = VZVirtioGraphicsScanoutConfiguration(
            widthInPixels: config.displayWidth,
            heightInPixels: config.displayHeight
        )
        graphicsDevice.scanouts = [scanout]
        vzConfig.graphicsDevices = [graphicsDevice]

        // Keyboard & mouse (USB for broad Linux compatibility)
        vzConfig.keyboards = [VZUSBKeyboardConfiguration()]
        vzConfig.pointingDevices = [VZUSBScreenCoordinatePointingDeviceConfiguration()]

        // Storage — main disk
        let diskPath = store.diskImagePath(for: config.id)
        try DiskImageService.createSparseImage(at: diskPath, sizeGB: config.diskSizeGB)
        let mainDisk = try VZDiskImageStorageDeviceAttachment(url: diskPath, readOnly: false)
        var storageDevices: [VZStorageDeviceConfiguration] = [
            VZVirtioBlockDeviceConfiguration(attachment: mainDisk)
        ]

        // ISO attachment (secondary, read-only) for installation
        if let isoPathString = config.isoPath,
           !isoPathString.isEmpty,
           FileManager.default.fileExists(atPath: isoPathString) {
            let isoURL = URL(fileURLWithPath: isoPathString)
            let isoAttachment = try VZDiskImageStorageDeviceAttachment(url: isoURL, readOnly: true)
            storageDevices.append(VZVirtioBlockDeviceConfiguration(attachment: isoAttachment))
        }
        vzConfig.storageDevices = storageDevices

        // Networking — NAT
        let networkDevice = VZVirtioNetworkDeviceConfiguration()
        networkDevice.attachment = VZNATNetworkDeviceAttachment()
        vzConfig.networkDevices = [networkDevice]

        // Audio — Virtio sound
        let audioDevice = VZVirtioSoundDeviceConfiguration()
        let outputStream = VZVirtioSoundDeviceOutputStreamConfiguration()
        outputStream.sink = VZHostAudioOutputStreamSink()
        let inputStream = VZVirtioSoundDeviceInputStreamConfiguration()
        inputStream.source = VZHostAudioInputStreamSource()
        audioDevice.streams = [outputStream, inputStream]
        vzConfig.audioDevices = [audioDevice]

        // Entropy (random number generator)
        vzConfig.entropyDevices = [VZVirtioEntropyDeviceConfiguration()]

        // Memory balloon
        vzConfig.memoryBalloonDevices = [VZVirtioTraditionalMemoryBalloonDeviceConfiguration()]

        // Serial console (pipe-based)
        let readPipe = Pipe()
        let writePipe = Pipe()
        self.serialReadPipe = readPipe
        self.serialWritePipe = writePipe

        let serialPort = VZVirtioConsoleDeviceSerialPortConfiguration()
        let serialAttachment = VZFileHandleSerialPortAttachment(
            fileHandleForReading: writePipe.fileHandleForReading,
            fileHandleForWriting: readPipe.fileHandleForWriting
        )
        serialPort.attachment = serialAttachment
        vzConfig.serialPorts = [serialPort]

        // Shared folder (Virtio file system)
        if let folderPath = config.sharedFolderPath,
           !folderPath.isEmpty,
           FileManager.default.fileExists(atPath: folderPath) {
            let sharedDir = VZSharedDirectory(url: URL(fileURLWithPath: folderPath), readOnly: false)
            let singleDirShare = VZSingleDirectoryShare(directory: sharedDir)
            let fsDevice = VZVirtioFileSystemDeviceConfiguration(tag: "shared")
            fsDevice.share = singleDirShare
            vzConfig.directorySharingDevices = [fsDevice]
        }

        // Machine identifier
        let machineIdPath = store.machineIdentifierPath(for: config.id)
        if let machineIdData = try? Data(contentsOf: machineIdPath) {
            vzConfig.platform = VZGenericPlatformConfiguration()
            if let machineId = VZGenericMachineIdentifier(dataRepresentation: machineIdData) {
                (vzConfig.platform as? VZGenericPlatformConfiguration)?.machineIdentifier = machineId
            }
        } else {
            let platform = VZGenericPlatformConfiguration()
            let machineId = VZGenericMachineIdentifier()
            platform.machineIdentifier = machineId
            try machineId.dataRepresentation.write(to: machineIdPath)
            vzConfig.platform = platform
        }

        try vzConfig.validate()
        return vzConfig
    }

    // MARK: - Lifecycle

    func start() async throws {
        let vzConfig = try buildConfiguration()
        let vm = VZVirtualMachine(configuration: vzConfig)
        vm.delegate = self
        self.virtualMachine = vm

        // Observe state changes via KVO
        stateObservation = vm.observe(\.state, options: [.new, .initial]) { [weak self] machine, _ in
            Task { @MainActor [weak self] in
                self?.state = machine.state
            }
        }

        // Read serial console output
        startReadingConsole()

        try await vm.start()
    }

    func stop() async throws {
        guard let vm = virtualMachine else { return }
        if vm.canRequestStop {
            try vm.requestStop()
            // Give 5 seconds for ACPI shutdown
            try await Task.sleep(nanoseconds: 5_000_000_000)
            if vm.state != .stopped {
                try await vm.stop()
            }
        } else {
            try await vm.stop()
        }
    }

    func forceStop() async throws {
        guard let vm = virtualMachine else { return }
        try await vm.stop()
    }

    func pause() async throws {
        guard let vm = virtualMachine else { return }
        try await vm.pause()
    }

    func resume() async throws {
        guard let vm = virtualMachine else { return }
        try await vm.resume()
    }

    // MARK: - Serial Console

    func sendToConsole(_ text: String) {
        guard let pipe = serialWritePipe else { return }
        if let data = text.data(using: .utf8) {
            pipe.fileHandleForWriting.write(data)
        }
    }

    private func startReadingConsole() {
        guard let pipe = serialReadPipe else { return }
        pipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            guard !data.isEmpty, let text = String(data: data, encoding: .utf8) else { return }
            Task { @MainActor [weak self] in
                self?.consoleOutput.append(text)
                // Keep console buffer reasonable
                if let output = self?.consoleOutput, output.count > 100_000 {
                    self?.consoleOutput = String(output.suffix(80_000))
                }
            }
        }
    }

    func cleanup() {
        stateObservation?.invalidate()
        stateObservation = nil
        serialReadPipe?.fileHandleForReading.readabilityHandler = nil
        serialReadPipe = nil
        serialWritePipe = nil
        virtualMachine = nil
    }
}

// MARK: - VZVirtualMachineDelegate

extension VMManager: VZVirtualMachineDelegate {
    nonisolated func virtualMachine(_ virtualMachine: VZVirtualMachine, didStopWithError error: Error) {
        Task { @MainActor in
            self.state = .stopped
            self.consoleOutput.append("\n[VM stopped with error: \(error.localizedDescription)]\n")
        }
    }

    nonisolated func guestDidStop(_ virtualMachine: VZVirtualMachine) {
        Task { @MainActor in
            self.state = .stopped
            self.consoleOutput.append("\n[Guest initiated shutdown]\n")
        }
    }
}
