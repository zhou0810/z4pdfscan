import Foundation

enum DiskImageService {
    enum DiskImageError: LocalizedError {
        case createFailed(String)

        var errorDescription: String? {
            switch self {
            case .createFailed(let reason):
                return "Failed to create disk image: \(reason)"
            }
        }
    }

    /// Creates a sparse RAW disk image at the given path.
    /// The file is allocated on-demand as the guest writes data.
    static func createSparseImage(at path: URL, sizeGB: Int) throws {
        let sizeBytes = UInt64(sizeGB) * 1024 * 1024 * 1024

        if FileManager.default.fileExists(atPath: path.path) {
            return // Already exists
        }

        FileManager.default.createFile(atPath: path.path, contents: nil)
        let fd = open(path.path, O_RDWR)
        guard fd >= 0 else {
            throw DiskImageError.createFailed("Cannot open file at \(path.path)")
        }
        defer { close(fd) }

        let result = ftruncate(fd, off_t(sizeBytes))
        guard result == 0 else {
            throw DiskImageError.createFailed("ftruncate failed with errno \(errno)")
        }
    }
}
