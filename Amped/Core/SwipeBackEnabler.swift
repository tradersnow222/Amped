//
//  SwipeBackEnabler.swift
//  Amped
//
//  Created by Sheraz Hussain on 29/11/2025.
//

import SwiftUI
import UIKit

/// Re-enables the interactive pop (swipe back) gesture even when the navigation bar is hidden.
struct SwipeBackEnabler: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        let controller = UIViewController()
        controller.view.backgroundColor = .clear
        
        // Defer to ensure the controller is in a navigation stack
        DispatchQueue.main.async {
            if let nav = controller.navigationController {
                nav.interactivePopGestureRecognizer?.isEnabled = true
                // Setting delegate to nil restores the default edge-swipe behavior
                nav.interactivePopGestureRecognizer?.delegate = nil
            }
        }
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}

extension View {
    /// Call this on any view within a NavigationStack to ensure swipe back works.
    func enableSwipeBack() -> some View {
        background(SwipeBackEnabler())
    }
}
