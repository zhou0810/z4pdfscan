import SwiftUI
import PDFKit

struct FolderDetailView: View {
    let folder: AppFolder
    @State private var pdfURLs: [URL] = []
    @State private var selectedPDFURL: URL?

    var body: some View {
        List {
            if pdfURLs.isEmpty {
                ContentUnavailableView(
                    "No Documents",
                    systemImage: "doc",
                    description: Text("Scan documents and save them to this folder.")
                )
            } else {
                ForEach(pdfURLs, id: \.self) { url in
                    Button {
                        selectedPDFURL = url
                    } label: {
                        HStack {
                            Image(systemName: "doc.richtext")
                                .foregroundStyle(.red)
                            VStack(alignment: .leading) {
                                Text(url.deletingPathExtension().lastPathComponent)
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                Text(fileSizeString(for: url))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .onDelete(perform: deletePDFs)
            }
        }
        .navigationTitle(folder.name)
        .onAppear {
            loadPDFs()
        }
        .sheet(item: $selectedPDFURL) { url in
            NavigationStack {
                PDFPreviewView(url: url)
                    .navigationTitle(url.deletingPathExtension().lastPathComponent)
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            ShareLink(item: url)
                        }
                        ToolbarItem(placement: .topBarLeading) {
                            Button("Done") {
                                selectedPDFURL = nil
                            }
                        }
                    }
            }
        }
    }

    private func loadPDFs() {
        pdfURLs = FileManagerService.listPDFs(in: folder)
    }

    private func deletePDFs(at offsets: IndexSet) {
        for index in offsets {
            FileManagerService.deletePDF(at: pdfURLs[index])
        }
        pdfURLs.remove(atOffsets: offsets)
    }

    private func fileSizeString(for url: URL) -> String {
        guard let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
              let size = attrs[.size] as? Int64 else {
            return ""
        }
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: size)
    }
}

extension URL: @retroactive Identifiable {
    public var id: String { absoluteString }
}

// MARK: - PDF Preview

struct PDFPreviewView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.document = PDFDocument(url: url)
        return pdfView
    }

    func updateUIView(_ uiView: PDFView, context: Context) {}
}
