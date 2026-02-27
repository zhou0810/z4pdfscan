import SwiftUI

@MainActor
final class AppViewModel: ObservableObject {
    @Published var vmConfigs: [VMConfiguration] = []
    @Published var selectedVMId: UUID?
    @Published var showCreateSheet = false
    @Published var errorMessage: String?
    @Published var showError = false

    private(set) var runningVMs: [UUID: VMManager] = [:]
    private let store = VMConfigStore.shared

    init() {
        reload()
    }

    func reload() {
        vmConfigs = store.loadAll()
    }

    // MARK: - VM CRUD

    func createVM(from viewModel: CreateVMViewModel) {
        let config = viewModel.buildConfig()
        do {
            try store.save(config)
            reload()
            selectedVMId = config.id
        } catch {
            showError(error.localizedDescription)
        }
    }

    func deleteVM(_ id: UUID) {
        // Stop if running
        if let manager = runningVMs[id] {
            Task {
                try? await manager.forceStop()
                manager.cleanup()
            }
            runningVMs.removeValue(forKey: id)
        }
        do {
            try store.delete(id)
            reload()
            if selectedVMId == id {
                selectedVMId = vmConfigs.first?.id
            }
        } catch {
            showError(error.localizedDescription)
        }
    }

    // MARK: - VM Lifecycle

    func vmManager(for id: UUID) -> VMManager? {
        runningVMs[id]
    }

    func vmState(for id: UUID) -> String {
        guard let manager = runningVMs[id] else { return "stopped" }
        switch manager.state {
        case .running: return "running"
        case .paused: return "paused"
        case .starting: return "starting"
        case .stopping: return "stopping"
        case .error: return "error"
        default: return "stopped"
        }
    }

    func startVM(_ id: UUID) {
        guard let config = vmConfigs.first(where: { $0.id == id }) else { return }

        let manager: VMManager
        if let existing = runningVMs[id] {
            manager = existing
        } else {
            manager = VMManager(config: config)
            runningVMs[id] = manager
        }

        Task {
            do {
                try await manager.start()
            } catch {
                showError("Failed to start VM: \(error.localizedDescription)")
            }
            objectWillChange.send()
        }
    }

    func stopVM(_ id: UUID) {
        guard let manager = runningVMs[id] else { return }
        Task {
            do {
                try await manager.stop()
            } catch {
                showError("Failed to stop VM: \(error.localizedDescription)")
            }
            objectWillChange.send()
        }
    }

    func forceStopVM(_ id: UUID) {
        guard let manager = runningVMs[id] else { return }
        Task {
            do {
                try await manager.forceStop()
            } catch {
                showError("Failed to force stop VM: \(error.localizedDescription)")
            }
            objectWillChange.send()
        }
    }

    func pauseVM(_ id: UUID) {
        guard let manager = runningVMs[id] else { return }
        Task {
            do {
                try await manager.pause()
            } catch {
                showError("Failed to pause VM: \(error.localizedDescription)")
            }
            objectWillChange.send()
        }
    }

    func resumeVM(_ id: UUID) {
        guard let manager = runningVMs[id] else { return }
        Task {
            do {
                try await manager.resume()
            } catch {
                showError("Failed to resume VM: \(error.localizedDescription)")
            }
            objectWillChange.send()
        }
    }

    // MARK: - Helpers

    private func showError(_ message: String) {
        errorMessage = message
        showError = true
    }
}
