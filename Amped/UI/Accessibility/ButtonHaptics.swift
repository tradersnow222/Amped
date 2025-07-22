import SwiftUI
import UIKit

/// Extension to add haptic feedback to SwiftUI buttons.
/// Uses the HapticFeedback utility to provide consistent feedback patterns.
/// Following Apple iOS standards: Light feedback for routine interactions
extension Button {
    /// Adds subtle light impact haptic feedback to a button's action (Apple iOS standard).
    /// - Returns: A button that provides subtle haptic feedback when tapped
    func hapticFeedback() -> some View {
        self.simultaneousGesture(
            TapGesture().onEnded { _ in
                HapticFeedback.buttonPress()
            }
        )
    }
    
    /// Adds specific haptic feedback to a button's action.
    /// - Parameter style: The style of haptic feedback to trigger
    /// - Returns: A button that provides the specified haptic feedback when tapped
    func hapticFeedback(_ style: HapticFeedback.FeedbackStyle) -> some View {
        self.simultaneousGesture(
            TapGesture().onEnded { _ in
                HapticFeedback.trigger(style)
            }
        )
    }
    
    /// Adds success haptic feedback to a button's action.
    /// - Returns: A button that provides success haptic feedback when tapped
    func successFeedback() -> some View {
        self.simultaneousGesture(
            TapGesture().onEnded { _ in
                HapticFeedback.success()
            }
        )
    }
    
    /// Adds error haptic feedback to a button's action.
    /// - Returns: A button that provides error haptic feedback when tapped
    func errorFeedback() -> some View {
        self.simultaneousGesture(
            TapGesture().onEnded { _ in
                HapticFeedback.error()
            }
        )
    }
}

/// Extension to add haptic feedback capability to any view, useful for custom buttons
extension View {
    /// Adds a tap gesture with haptic feedback to any view
    /// - Parameter style: The style of haptic feedback to trigger (defaults to light for subtlety)
    /// - Returns: A view that triggers haptic feedback when tapped
    func withHapticFeedback(_ style: HapticFeedback.FeedbackStyle = .light) -> some View {
        self.simultaneousGesture(
            TapGesture().onEnded { _ in
                HapticFeedback.trigger(style)
            }
        )
    }
    
    /// Adds subtle light impact haptic feedback to any view (Apple iOS standard)
    /// - Returns: A view that provides subtle haptic feedback when tapped
    func hapticFeedback() -> some View {
        self.simultaneousGesture(
            TapGesture().onEnded { _ in
                HapticFeedback.buttonPress()
            }
        )
    }
    
    /// Adds specific haptic feedback to any view
    /// - Parameter style: The style of haptic feedback to trigger
    /// - Returns: A view that provides the specified haptic feedback when tapped
    func hapticFeedback(_ style: HapticFeedback.FeedbackStyle) -> some View {
        self.simultaneousGesture(
            TapGesture().onEnded { _ in
                HapticFeedback.trigger(style)
            }
        )
    }
} 