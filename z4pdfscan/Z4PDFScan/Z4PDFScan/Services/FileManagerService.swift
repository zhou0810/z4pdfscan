import Foundation
import PDFKit

enum FileManagerService {

    static var documentsURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    static var scansDirectory: URL {
        documentsURL.appendingPathComponent("Scans", isDirectory: true)
    }

    static func ensureScansDirectory() {
        let fm = FileManager.default
        if !fm.fileExists(atPath: scansDirectory.path) {
            try? fm.createDirectory(at: scansDirectory, withIntermediateDirectories: true)
        }
    }

    // MARK: - Folders

    static func listFolders() -> [AppFolder] {
        ensureScansDirectory()
        let fm = FileManager.default
        guard let contents = try? fm.contentsOfDirectory(
            at: scansDirectory,
            includingPropertiesForKeys: [.creationDateKey, .isDirectoryKey],
            options: .skipsHiddenFiles
        ) else {
            return []
        }

        return contents.compactMap { url in
            let resourceValues = try? url.resourceValues(forKeys: [.isDirectoryKey, .creationDateKey])
            guard resourceValues?.isDirectory == true else { return nil }
            return AppFolder(
                name: url.lastPathComponent,
                url: url,
                createdDate: resourceValues?.creationDate ?? Date()
            )
        }
        .sorted { $0.createdDate > $1.createdDate }
    }

    static func createFolder(name: String) -> AppFolder? {
        ensureScansDirectory()
        let folderURL = scansDirectory.appendingPathComponent(name, isDirectory: true)
        do {
            try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true)
            return AppFolder(name: name, url: folderURL)
        } catch {
            return nil
        }
    }

    static func deleteFolder(at url: URL) {
        try? FileManager.default.removeItem(at: url)
    }

    // MARK: - PDFs

    static func listPDFs(in folder: AppFolder) -> [URL] {
        let fm = FileManager.default
        guard let contents = try? fm.contentsOfDirectory(
            at: folder.url,
            includingPropertiesForKeys: [.creationDateKey],
            options: .skipsHiddenFiles
        ) else {
            return []
        }

        return contents
            .filter { $0.pathExtension.lowercased() == "pdf" }
            .sorted { url1, url2 in
                let date1 = (try? url1.resourceValues(forKeys: [.creationDateKey]))?.creationDate ?? Date.distantPast
                let date2 = (try? url2.resourceValues(forKeys: [.creationDateKey]))?.creationDate ?? Date.distantPast
                return date1 > date2
            }
    }

    static func savePDF(_ document: PDFDocument, name: String, folder: AppFolder) -> URL? {
        let fileName = name.hasSuffix(".pdf") ? name : "\(name).pdf"
        let fileURL = folder.url.appendingPathComponent(fileName)
        if document.write(to: fileURL) {
            return fileURL
        }
        return nil
    }

    static func deletePDF(at url: URL) {
        try? FileManager.default.removeItem(at: url)
    }
}
