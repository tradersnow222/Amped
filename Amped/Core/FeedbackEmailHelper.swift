//
//  FeedbackEmailHelper.swift
//  Amped
//
//  Created by Sheraz Hussain on 23/11/2025.
//

import SwiftUI
import MessageUI

final class FeedbackEmailHelper: NSObject, MFMailComposeViewControllerDelegate {

    static let shared = FeedbackEmailHelper()

    func sendFeedbackEmail(body: String) {
        guard MFMailComposeViewController.canSendMail() else {
            openMailFallback(body: body)
            return
        }

        let mailVC = MFMailComposeViewController()
        mailVC.mailComposeDelegate = self
        mailVC.setToRecipients(["sherazhussain360@gmail.com"])
        mailVC.setSubject("App Feedback")
        mailVC.setMessageBody(body, isHTML: false)

        present(mailVC)
    }

    private func present(_ vc: UIViewController) {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let root = scene.windows.first?.rootViewController else { return }

        root.present(vc, animated: true)
    }

    private func openMailFallback(body: String) {
        let email = "sherazhussain360@gmail.com"
        let subject = "App Feedback"
        let bodyEncoded = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""

        let urlString = "mailto:\(email)?subject=\(subject)&body=\(bodyEncoded)"

        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }

    func mailComposeController(_ controller: MFMailComposeViewController,
                               didFinishWith result: MFMailComposeResult,
                               error: Error?) {
        controller.dismiss(animated: true)
    }
}
