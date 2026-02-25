# CLAUDE.md

## Project Overview

Z4PDFScan is an iOS 16+ document scanner app built with Swift/SwiftUI using MVVM architecture. No third-party dependencies.

## Tech Stack

- **Language**: Swift
- **UI**: SwiftUI (iOS 16+)
- **Scanning**: VisionKit (`VNDocumentCameraViewController`)
- **PDF**: PDFKit
- **Architecture**: MVVM (Models / Services / ViewModels / Views)

## Project Structure

```
Z4PDFScan/Z4PDFScan/
├── Models/          Data types (ScannedPage, AppFolder, ResolutionOption)
├── Services/        Stateless business logic (ImageProcessing, PDFGeneration, FileManager)
├── ViewModels/      ObservableObject classes (Scanner, Save, Home)
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

## Build

No `.xcodeproj` is checked in. To build:
1. Create a new Xcode App project (SwiftUI, iOS 16+) named `Z4PDFScan`
2. Replace generated sources with files from `Z4PDFScan/Z4PDFScan/`
3. Build with `Cmd+B`

Camera scanning requires a physical device. Navigation and PDF generation work in Simulator.

## Common Tasks

- **Adding a new view**: Create in `Views/`, follow existing SwiftUI patterns
- **Adding a new service**: Create as `enum` with static methods in `Services/`
- **Adding a new model**: Create `Identifiable` struct in `Models/`
