import SwiftUI

struct PagePreviewView: View {
    @ObservedObject var scannerVM: ScannerViewModel
    @State private var isEditing = false

    private let columns = [
        GridItem(.adaptive(minimum: 150), spacing: 12)
    ]

    var body: some View {
        ScrollView {
            if scannerVM.pages.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "doc.on.doc")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text("No Pages")
                        .font(.title3)
                        .fontWeight(.semibold)
                    Text("Scanned pages will appear here.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 100)
            } else {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(Array(scannerVM.pages.enumerated()), id: \.element.id) { index, page in
                        ZStack(alignment: .topTrailing) {
                            PageThumbnailView(thumbnailURL: page.thumbnailURL)
                                .overlay(alignment: .bottomLeading) {
                                    Text("Page \(index + 1)")
                                        .font(.caption2)
                                        .fontWeight(.medium)
                                        .padding(4)
                                        .background(.ultraThinMaterial)
                                        .cornerRadius(4)
                                        .padding(4)
                                }

                            if isEditing {
                                Button {
                                    withAnimation {
                                        scannerVM.deletePage(at: IndexSet(integer: index))
                                    }
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.title3)
                                        .foregroundStyle(.white, .red)
                                }
                                .padding(4)
                            }
                        }
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Scanned Pages")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if !scannerVM.pages.isEmpty {
                    NavigationLink {
                        SaveDocumentView(scannerVM: scannerVM)
                    } label: {
                        Text("Save")
                            .fontWeight(.semibold)
                    }
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                if !scannerVM.pages.isEmpty {
                    Button(isEditing ? "Done" : "Edit") {
                        withAnimation { isEditing.toggle() }
                    }
                }
            }
        }
    }
}

// MARK: - Thumbnail View

struct PageThumbnailView: View {
    let thumbnailURL: URL

    var body: some View {
        AsyncImageFromURL(url: thumbnailURL)
            .frame(minHeight: 200)
            .background(Color(.systemGray6))
            .cornerRadius(8)
            .shadow(color: .black.opacity(0.1), radius: 2, y: 1)
    }
}

struct AsyncImageFromURL: View {
    let url: URL
    @State private var uiImage: UIImage?

    var body: some View {
        Group {
            if let uiImage {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 200)
            }
        }
        .onAppear {
            loadImage()
        }
    }

    private func loadImage() {
        DispatchQueue.global(qos: .userInitiated).async {
            if let data = try? Data(contentsOf: url),
               let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    self.uiImage = image
                }
            }
        }
    }
}
