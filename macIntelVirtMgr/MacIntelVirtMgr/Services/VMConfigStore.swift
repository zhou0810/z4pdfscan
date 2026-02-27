import Foundation

final class VMConfigStore {
    static let shared = VMConfigStore()

    private let fileManager = FileManager.default
    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        e.outputFormatting = [.prettyPrinted, .sortedKeys]
        return e
    }()
    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    private var baseDirectory: URL {
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return appSupport.appendingPathComponent("MacIntelVirtMgr", isDirectory: true)
    }

    private init() {
        try? fileManager.createDirectory(at: baseDirectory, withIntermediateDirectories: true)
    }

    // MARK: - Per-VM paths

    func vmDirectory(for id: UUID) -> URL {
        baseDirectory.appendingPathComponent(id.uuidString, isDirectory: true)
    }

    func configFile(for id: UUID) -> URL {
        vmDirectory(for: id).appendingPathComponent("config.json")
    }

    func diskImagePath(for id: UUID) -> URL {
        vmDirectory(for: id).appendingPathComponent("disk.img")
    }

    func efiVariableStorePath(for id: UUID) -> URL {
        vmDirectory(for: id).appendingPathComponent("efi-vars.fd")
    }

    func machineIdentifierPath(for id: UUID) -> URL {
        vmDirectory(for: id).appendingPathComponent("machine-id.bin")
    }

    // MARK: - CRUD

    func loadAll() -> [VMConfiguration] {
        guard let contents = try? fileManager.contentsOfDirectory(
            at: baseDirectory,
            includingPropertiesForKeys: nil,
            options: .skipsHiddenFiles
        ) else {
            return []
        }

        return contents.compactMap { dir in
            let configURL = dir.appendingPathComponent("config.json")
            guard let data = try? Data(contentsOf: configURL) else { return nil }
            return try? decoder.decode(VMConfiguration.self, from: data)
        }
        .sorted { $0.createdDate < $1.createdDate }
    }

    func save(_ config: VMConfiguration) throws {
        let dir = vmDirectory(for: config.id)
        try fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        let data = try encoder.encode(config)
        try data.write(to: configFile(for: config.id))
    }

    func delete(_ id: UUID) throws {
        let dir = vmDirectory(for: id)
        if fileManager.fileExists(atPath: dir.path) {
            try fileManager.removeItem(at: dir)
        }
    }
}
