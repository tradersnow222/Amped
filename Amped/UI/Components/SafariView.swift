import SwiftUI
import SafariServices

/// In-app browser using SFSafariViewController (Instagram-style link open)
/// Rules applied: Simplicity is KING; SwiftUI-first; Security over performance
struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        let config = SFSafariViewController.Configuration()
        config.entersReaderIfAvailable = false
        config.barCollapsingEnabled = true

        let controller = SFSafariViewController(url: url, configuration: config)
        controller.modalPresentationStyle = .pageSheet
        controller.dismissButtonStyle = .close
        controller.preferredBarTintColor = UIColor.systemBackground
        controller.preferredControlTintColor = UIColor.label
        return controller
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {
        // No-op
    }
}


