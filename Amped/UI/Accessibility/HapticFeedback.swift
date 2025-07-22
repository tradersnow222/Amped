import SwiftUI
import UIKit

/// Centralized utility for generating haptic feedback throughout the app.
/// Uses UIKit feedback generators to provide a consistent experience.
/// 
/// Usage Guidelines:
/// - Light: Subtle interactions, picker changes, minor selections
/// - Medium: Standard button presses, confirmations, default choice
/// - Heavy: Important actions, major completions, significant state changes
/// - Selection: For selection changes in pickers, toggles
/// - Success/Warning/Error: For operation outcomes
class HapticFeedback {
    
    /// Haptic feedback style options following Apple HIG
    enum FeedbackStyle {
        /// Light impact - subtle feedback for minor interactions
        case light
        /// Medium impact - standard feedback for most interactions
        case medium
        /// Heavy impact - stronger feedback for significant actions
        case heavy
        /// Success notification - for completed actions
        case success
        /// Warning notification - for actions requiring attention
        case warning
        /// Error notification - for failed actions
        case error
        /// Selection feedback - for selection changes
        case selection
    }
    
    /// Triggers the appropriate haptic feedback based on the specified style
    /// - Parameter style: The desired haptic feedback style
    static func trigger(_ style: FeedbackStyle) {
        switch style {
        case .light:
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.prepare()
            generator.impactOccurred()
            
        case .medium:
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.prepare()
            generator.impactOccurred()
            
        case .heavy:
            let generator = UIImpactFeedbackGenerator(style: .heavy)
            generator.prepare()
            generator.impactOccurred()
            
        case .success:
            let generator = UINotificationFeedbackGenerator()
            generator.prepare()
            generator.notificationOccurred(.success)
            
        case .warning:
            let generator = UINotificationFeedbackGenerator()
            generator.prepare()
            generator.notificationOccurred(.warning)
            
        case .error:
            let generator = UINotificationFeedbackGenerator()
            generator.prepare()
            generator.notificationOccurred(.error)
            
        case .selection:
            let generator = UISelectionFeedbackGenerator()
            generator.prepare()
            generator.selectionChanged()
        }
    }
    
    /// Convenience method for subtle button feedback (Apple iOS standard for routine buttons)
    static func buttonPress() {
        trigger(.light)
    }
    
    /// Convenience method for important button feedback (for significant actions)
    static func importantButtonPress() {
        trigger(.medium)
    }
    
    /// Convenience method for major completion feedback (for completing flows)
    static func majorCompletion() {
        trigger(.heavy)
    }
    
    /// Convenience method for success feedback
    static func success() {
        trigger(.success)
    }
    
    /// Convenience method for error feedback
    static func error() {
        trigger(.error)
    }
    
    /// Convenience method for selection feedback
    static func selection() {
        trigger(.selection)
    }
} 