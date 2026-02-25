import UIKit
import Combine

class ScannerViewModel: ObservableObject {
    @Published var pages: [ScannedPage] = []

    func addScannedImages(_ images: [UIImage]) {
        for image in images {
            let imageURL = ImageProcessingService.saveScanToTempFile(image)
            let thumbnailURL = ImageProcessingService.generateThumbnail(from: imageURL)
            let page = ScannedPage(imageURL: imageURL, thumbnailURL: thumbnailURL)
            pages.append(page)
        }
    }

    func deletePage(at offsets: IndexSet) {
        let pagesToDelete = offsets.map { pages[$0] }
        for page in pagesToDelete {
            try? FileManager.default.removeItem(at: page.imageURL)
            try? FileManager.default.removeItem(at: page.thumbnailURL)
        }
        pages.remove(atOffsets: offsets)
    }

    func movePage(from source: IndexSet, to destination: Int) {
        pages.move(fromOffsets: source, toOffset: destination)
    }

    func clearAll() {
        for page in pages {
            try? FileManager.default.removeItem(at: page.imageURL)
            try? FileManager.default.removeItem(at: page.thumbnailURL)
        }
        pages.removeAll()
        ImageProcessingService.cleanupTempFiles()
    }
}
