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
    @Published var useClaudeOCR: Bool = false
    @Published var processingStatus: String = ""
    @Published var ocrError: String?

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

    // MARK: - Claude OCR

    func saveWithOCR(pages: [ScannedPage]) {
        guard let folder = selectedFolder else { return }
        let apiKey = SettingsViewModel.storedAPIKey()
        guard !apiKey.isEmpty else { return }

        isSaving = true
        ocrError = nil
        processingStatus = "Sending images to Claude..."

        Task {
            do {
                let text = try await ClaudeAPIService.extractText(from: pages, apiKey: apiKey)
                await MainActor.run { processingStatus = "Generating text PDF..." }
                let pdf = TextPDFService.generateTextPDF(from: text)
                let url = FileManagerService.savePDF(pdf, name: documentName, folder: folder)
                await MainActor.run {
                    savedURL = url
                    isSaving = false
                    processingStatus = ""
                }
            } catch {
                await MainActor.run {
                    ocrError = error.localizedDescription
                    isSaving = false
                    processingStatus = ""
                }
            }
        }
    }

    func exportWithOCR(pages: [ScannedPage]) {
        let apiKey = SettingsViewModel.storedAPIKey()
        guard !apiKey.isEmpty else { return }

        isSaving = true
        ocrError = nil
        processingStatus = "Sending images to Claude..."

        Task {
            do {
                let text = try await ClaudeAPIService.extractText(from: pages, apiKey: apiKey)
                await MainActor.run { processingStatus = "Generating text PDF..." }
                let pdf = TextPDFService.generateTextPDF(from: text)
                let tempURL = FileManager.default.temporaryDirectory
                    .appendingPathComponent("\(documentName).pdf")
                pdf.write(to: tempURL)
                await MainActor.run {
                    exportURL = tempURL
                    isSaving = false
                    processingStatus = ""
                }
            } catch {
                await MainActor.run {
                    ocrError = error.localizedDescription
                    isSaving = false
                    processingStatus = ""
                }
            }
        }
    }
}
