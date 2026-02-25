import Foundation

struct ScannedPage: Identifiable {
    let id: UUID
    let imageURL: URL
    let thumbnailURL: URL

    init(id: UUID = UUID(), imageURL: URL, thumbnailURL: URL) {
        self.id = id
        self.imageURL = imageURL
        self.thumbnailURL = thumbnailURL
    }
}
