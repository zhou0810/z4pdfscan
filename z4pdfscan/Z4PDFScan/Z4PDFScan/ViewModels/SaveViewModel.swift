import Foundation
import Combine
import PDFKit

class SaveViewModel: ObservableObject {
    @Published var documentName: String
    @Published var selectedResolution: ResolutionOption = .medium
    @Published var selectedFolder: AppFolder?
    @Published var isSaving: Bool = false
    @Published var savedURL: URL?
    @Published var exportURL: URL?

    init() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HHmmss"
        self.documentName = "Scan_\(formatter.string(from: Date()))"
    }

    func save(pages: [ScannedPage]) {
        guard let folder = selectedFolder else { return }
        isSaving = true

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            let pdf = PDFGenerationService.generatePDF(pages: pages, resolution: self.selectedResolution)
            let url = FileManagerService.savePDF(pdf, name: self.documentName, folder: folder)

            DispatchQueue.main.async {
                self.savedURL = url
                self.isSaving = false
            }
        }
    }

    func generateExportPDF(pages: [ScannedPage]) {
        isSaving = true

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            let pdf = PDFGenerationService.generatePDF(pages: pages, resolution: self.selectedResolution)
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent("\(self.documentName).pdf")
            pdf.write(to: tempURL)

            DispatchQueue.main.async {
                self.exportURL = tempURL
                self.isSaving = false
            }
        }
    }
}
