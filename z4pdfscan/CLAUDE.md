# CLAUDE.md

## Project Overview

Z4PDFScan is an iOS 16+ document scanner app built with Swift/SwiftUI using MVVM architecture. No third-party dependencies.

## Tech Stack

- **Language**: Swift
- **UI**: SwiftUI (iOS 16+)
- **Scanning**: VisionKit (`VNDocumentCameraViewController`)
- **PDF**: PDFKit, Core Text (`UIGraphicsPDFRenderer` + `CTFramesetter`)
- **AI/OCR**: Claude API (vision model for text extraction)
- **Architecture**: MVVM (Models / Services / ViewModels / Views)

## Project Structure

```
Z4PDFScan/Z4PDFScan/
├── Models/          Data types (ScannedPage, AppFolder, ResolutionOption)
├── Services/        Stateless business logic (ImageProcessing, PDFGeneration, FileManager, ClaudeAPI, TextPDF)
├── ViewModels/      ObservableObject classes (Scanner, Save, Home, Settings)
├── Views/           SwiftUI views and UIKit bridges
├── Assets.xcassets/ App icons and colors
└── Info.plist       Camera usage description
```

## Conventions

- Services are implemented as `enum` with static methods (no instances)
- ViewModels use `ObservableObject` + `@Published` (iOS 16 compatible)
- Views use `@StateObject` for ownership, `@EnvironmentObject` for shared access
- UIKit bridges use `UIViewControllerRepresentable` with Coordinator pattern
- Images are written to temp files immediately to manage memory; views load thumbnails from disk
- File storage lives under `Documents/Scans/` with subfolders
- Claude API key stored in `UserDefaults` under `"claude_api_key"`

## AI OCR Feature

- **ClaudeAPIService**: Sends scanned page images (base64 JPEG) to Claude vision API (`claude-sonnet-4-20250514`) for text extraction with Markdown formatting
- **TextPDFService**: Parses Markdown → `NSAttributedString` with styled fonts, renders multi-page PDF via `UIGraphicsPDFRenderer` + Core Text
- **SettingsView/ViewModel**: API key management via `UserDefaults`
- Toggle "AI Text PDF" in SaveDocumentView to switch between image-based and text-based PDF output
- Text extraction preserves headings, bold, italic, lists; embedded images/icons are not reproduced

## Build

The `.xcodeproj` is checked in. To build:
1. Open `Z4PDFScan/Z4PDFScan.xcodeproj` in Xcode
2. Build with `Cmd+B`

CLI build:
```
xcodebuild -project Z4PDFScan/Z4PDFScan.xcodeproj -scheme Z4PDFScan -destination 'generic/platform=iOS' -allowProvisioningUpdates build
```

Camera scanning requires a physical device. Navigation and PDF generation work in Simulator.

## Common Tasks

- **Adding a new view**: Create in `Views/`, follow existing SwiftUI patterns
- **Adding a new service**: Create as `enum` with static methods in `Services/`
- **Adding a new model**: Create `Identifiable` struct in `Models/`
