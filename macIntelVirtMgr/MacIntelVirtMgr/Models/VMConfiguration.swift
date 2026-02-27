import Foundation

struct VMConfiguration: Codable, Identifiable {
    var id: UUID
    var name: String
    var cpuCount: Int
    var memorySizeMB: Int
    var diskSizeGB: Int
    var isoPath: String?
    var displayWidth: Int
    var displayHeight: Int
    var sharedFolderPath: String?
    var createdDate: Date

    init(
        id: UUID = UUID(),
        name: String,
        cpuCount: Int = 2,
        memorySizeMB: Int = 4096,
        diskSizeGB: Int = 64,
        isoPath: String? = nil,
        displayWidth: Int = 1920,
        displayHeight: Int = 1080,
        sharedFolderPath: String? = nil,
        createdDate: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.cpuCount = cpuCount
        self.memorySizeMB = memorySizeMB
        self.diskSizeGB = diskSizeGB
        self.isoPath = isoPath
        self.displayWidth = displayWidth
        self.displayHeight = displayHeight
        self.sharedFolderPath = sharedFolderPath
        self.createdDate = createdDate
    }
}
