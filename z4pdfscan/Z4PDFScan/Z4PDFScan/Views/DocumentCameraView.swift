import SwiftUI
import VisionKit

struct DocumentCameraView: UIViewControllerRepresentable {
    var onScanCompleted: ([UIImage]) -> Void
    var onCancelled: () -> Void

    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let controller = VNDocumentCameraViewController()
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onScanCompleted: onScanCompleted, onCancelled: onCancelled)
    }

    class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        let onScanCompleted: ([UIImage]) -> Void
        let onCancelled: () -> Void

        init(onScanCompleted: @escaping ([UIImage]) -> Void, onCancelled: @escaping () -> Void) {
            self.onScanCompleted = onScanCompleted
            self.onCancelled = onCancelled
        }

        func documentCameraViewController(
            _ controller: VNDocumentCameraViewController,
            didFinishWith scan: VNDocumentCameraScan
        ) {
            var images: [UIImage] = []
            for i in 0..<scan.pageCount {
                images.append(scan.imageOfPage(at: i))
            }
            onScanCompleted(images)
        }

        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            onCancelled()
        }

        func documentCameraViewController(
            _ controller: VNDocumentCameraViewController,
            didFailWithError error: Error
        ) {
            onCancelled()
        }
    }
}
