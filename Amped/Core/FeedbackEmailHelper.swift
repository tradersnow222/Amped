//
//  FeedbackEmailHelper.swift
//  Amped
//
//  Created by Sheraz Hussain on 23/11/2025.
//

import SwiftUI
import MessageUI

final class FeedbackEmailHelper: NSObject {
    
    static let shared = FeedbackEmailHelper()
    private override init() {}

    private let recipient = "amped.lifespan@gmail.com"
    private let subject = "App Feedback - Amped"

    // MARK: - Public API
    func sendFeedbackEmail(body: String) {
        let encodedBody = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let encodedSubject = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""

        // 1. Try Gmail App
        if let gmailURL = URL(string: "googlegmail://co?to=\(recipient)&subject=\(encodedSubject)&body=\(encodedBody)"),
           UIApplication.shared.canOpenURL(gmailURL) {
            UIApplication.shared.open(gmailURL, options: [:], completionHandler: nil)
            return
        }

        // 2. Try Apple Mail App
        if MFMailComposeViewController.canSendMail() {
            presentMailComposer(body: body)
            return
        }

        // 3. Fallback to mailto via Safari
        if let mailto = URL(string: "mailto:\(recipient)?subject=\(encodedSubject)&body=\(encodedBody)"),
           UIApplication.shared.canOpenURL(mailto) {
            UIApplication.shared.open(mailto, options: [:], completionHandler: nil)
            return
        }

        print("❌ No email client available on this device.")
    }

    // MARK: - Mail Composer
    private func presentMailComposer(body: String) {
        let mailVC = MFMailComposeViewController()
        mailVC.mailComposeDelegate = self
        mailVC.setToRecipients([recipient])
        mailVC.setSubject(subject)
        mailVC.setMessageBody(body, isHTML: false)

        guard let rootVC = UIApplication.shared.topViewController() else {
            print("❌ Could not find root view controller")
            return
        }

        rootVC.present(mailVC, animated: true)
    }
}

// MARK: - Mail Delegate
extension FeedbackEmailHelper: MFMailComposeViewControllerDelegate {

    func mailComposeController(
        _ controller: MFMailComposeViewController,
        didFinishWith result: MFMailComposeResult,
        error: Error?
    ) {
        controller.dismiss(animated: true)

        if let error = error {
            print("❌ Mail error: \(error.localizedDescription)")
            return
        }

        switch result {
        case .sent:
            print("✅ Feedback email sent")
        case .cancelled:
            print("✖️ Feedback cancelled")
        case .saved:
            print("📩 Draft saved")
        case .failed:
            print("❌ Failed to send email")
        @unknown default:
            break
        }
    }
}

extension UIApplication {
    
    func topViewController(
        base: UIViewController? = UIApplication.shared.connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.keyWindow }
            .first?.rootViewController
    ) -> UIViewController? {

        if let nav = base as? UINavigationController {
            return topViewController(base: nav.visibleViewController)
        }

        if let tab = base as? UITabBarController, let selected = tab.selectedViewController {
            return topViewController(base: selected)
        }

        if let presented = base?.presentedViewController {
            return topViewController(base: presented)
        }

        return base
    }
}
