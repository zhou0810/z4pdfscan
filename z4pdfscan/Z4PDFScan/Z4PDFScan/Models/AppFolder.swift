import Foundation

struct AppFolder: Identifiable {
    let id: UUID
    let name: String
    let url: URL
    let createdDate: Date

    init(id: UUID = UUID(), name: String, url: URL, createdDate: Date = Date()) {
        self.id = id
        self.name = name
        self.url = url
        self.createdDate = createdDate
    }
}
