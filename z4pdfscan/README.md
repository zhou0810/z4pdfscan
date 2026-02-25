# Z4PDFScan

An iOS 16+ document scanner app built with SwiftUI, VisionKit, and PDFKit. Scan physical documents with your camera, preview and reorder pages, choose resolution presets, and save or export as PDF.

## Features

- **Document Scanning** — Uses VisionKit's `VNDocumentCameraViewController` for automatic edge detection and perspective correction
- **Page Management** — Preview scanned pages in a thumbnail grid, reorder pages, and delete unwanted ones
- **Resolution Presets** — Choose between Small (1024px), Medium (2048px), or Original quality when generating PDFs
- **Folder Organization** — Create folders to organize your scanned documents
- **PDF Generation** — Converts scanned images into multi-page PDFs using PDFKit
- **Export to Files** — Share PDFs via the system document picker or share sheet
- **Memory Efficient** — Images are written to temp files immediately; thumbnails are loaded on demand

## Architecture

MVVM pattern with SwiftUI:

```
Models/          → Data types (ScannedPage, AppFolder, ResolutionOption)
Services/        → Business logic (ImageProcessing, PDFGeneration, FileManager)
ViewModels/      → State management (Scanner, Save, Home)
Views/           → SwiftUI views and UIKit bridges
```

## Requirements

- iOS 16.0+
- Xcode 15+
- A physical device for camera scanning (Simulator supports navigation and PDF generation only)

## Setup

1. Open Xcode → **File > New > Project > App** (SwiftUI, iOS 16+)
2. Name the project `Z4PDFScan`
3. Replace the generated source files with the contents of `Z4PDFScan/Z4PDFScan/`
4. Build and run (`Cmd+B`, `Cmd+R`)

## Usage

1. Launch the app and create a folder
2. Tap the scan button to open the document camera
3. Scan one or more pages — the camera auto-detects document edges
4. Review pages in the preview grid — edit to delete, or tap Save
5. Choose a file name, resolution, and destination folder
6. Save to the app or export to Files

## License

MIT
