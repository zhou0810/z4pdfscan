import UIKit

enum ImageProcessingService {

    private static var tempDirectory: URL {
        FileManager.default.temporaryDirectory.appendingPathComponent("Z4PDFScan", isDirectory: true)
    }

    static func ensureTempDirectory() {
        let fm = FileManager.default
        if !fm.fileExists(atPath: tempDirectory.path) {
            try? fm.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        }
    }

    static func saveScanToTempFile(_ image: UIImage) -> URL {
        ensureTempDirectory()
        let fileName = UUID().uuidString + ".jpg"
        let fileURL = tempDirectory.appendingPathComponent(fileName)
        if let data = image.jpegData(compressionQuality: 0.9) {
            try? data.write(to: fileURL)
        }
        return fileURL
    }

    static func generateThumbnail(from imageURL: URL, maxSize: CGFloat = 200) -> URL {
        ensureTempDirectory()
        let thumbFileName = UUID().uuidString + "_thumb.jpg"
        let thumbURL = tempDirectory.appendingPathComponent(thumbFileName)

        guard let imageData = try? Data(contentsOf: imageURL),
              let image = UIImage(data: imageData) else {
            return thumbURL
        }

        let scale = min(maxSize / image.size.width, maxSize / image.size.height, 1.0)
        let newSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)

        let renderer = UIGraphicsImageRenderer(size: newSize)
        let thumbnailData = renderer.jpegData(withCompressionQuality: 0.6) { context in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
        try? thumbnailData.write(to: thumbURL)

        return thumbURL
    }

    static func downscaleImage(at imageURL: URL, resolution: ResolutionOption) -> Data? {
        guard let imageData = try? Data(contentsOf: imageURL),
              let image = UIImage(data: imageData) else {
            return nil
        }

        if resolution == .original {
            return image.jpegData(compressionQuality: resolution.jpegQuality)
        }

        let scale = min(resolution.maxWidth / image.size.width, 1.0)
        let newSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)

        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.jpegData(withCompressionQuality: resolution.jpegQuality) { context in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }

    static func cleanupTempFiles() {
        let fm = FileManager.default
        guard let files = try? fm.contentsOfDirectory(at: tempDirectory, includingPropertiesForKeys: nil) else {
            return
        }
        for file in files {
            try? fm.removeItem(at: file)
        }
    }
}
