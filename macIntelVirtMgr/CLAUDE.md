# MacIntelVirtMgr

macOS app for creating and running Linux virtual machines on Intel Macs using Apple's Virtualization.framework.

## Build

```bash
# Generate Xcode project (requires xcodegen)
xcodegen generate

# Build from command line
xcodebuild -project MacIntelVirtMgr.xcodeproj -scheme MacIntelVirtMgr build
```

## Architecture

- **Pattern**: MVVM (Models → Services → ViewModels → Views)
- **Framework**: Virtualization.framework (native, no QEMU)
- **UI**: SwiftUI with NavigationSplitView
- **Deployment target**: macOS 13.0
- **Sandbox**: OFF (required for virtualization entitlement)

## Key Conventions

- All VM operations run on `@MainActor` (VZVirtualMachine requirement)
- VM configs stored as JSON in `~/Library/Application Support/MacIntelVirtMgr/<uuid>/config.json`
- Disk images are sparse RAW files created via `ftruncate()`
- EFI variable store and machine identifier are persisted per-VM
- ISO attached as secondary read-only block device during installation
- Use `if #available(macOS 14.0, *)` to gate newer Virtualization APIs

## Project Structure

- `project.yml` — XcodeGen specification
- `MacIntelVirtMgr/Models/` — Data models (VMConfiguration)
- `MacIntelVirtMgr/Services/` — VM engine, disk creation, config persistence
- `MacIntelVirtMgr/ViewModels/` — App state, form state
- `MacIntelVirtMgr/Views/` — SwiftUI views
