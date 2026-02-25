import UIKit
import PDFKit

enum PDFGenerationService {

    static func generatePDF(pages: [ScannedPage], resolution: ResolutionOption) -> PDFDocument {
        let pdfDocument = PDFDocument()

        for (index, page) in pages.enumerated() {
            guard let imageData = ImageProcessingService.downscaleImage(at: page.imageURL, resolution: resolution),
                  let image = UIImage(data: imageData) else {
                continue
            }

            let pageRect = CGRect(origin: .zero, size: image.size)
            let renderer = UIGraphicsImageRenderer(size: pageRect.size)
            let fullImage = renderer.image { context in
                image.draw(in: pageRect)
            }

            if let pdfPage = PDFPage(image: fullImage) {
                pdfDocument.insert(pdfPage, at: index)
            }
        }

        return pdfDocument
    }
}
