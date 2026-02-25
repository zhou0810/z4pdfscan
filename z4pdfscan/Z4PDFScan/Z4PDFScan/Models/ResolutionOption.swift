import Foundation
import CoreGraphics

enum ResolutionOption: String, CaseIterable, Identifiable {
    case small = "Small"
    case medium = "Medium"
    case original = "Original"

    var id: String { rawValue }

    var maxWidth: CGFloat {
        switch self {
        case .small: return 1024
        case .medium: return 2048
        case .original: return .greatestFiniteMagnitude
        }
    }

    var jpegQuality: CGFloat {
        switch self {
        case .small: return 0.5
        case .medium: return 0.75
        case .original: return 1.0
        }
    }
}
