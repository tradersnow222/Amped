import SwiftUI

/// Consistent primary button style for the entire app
/// Following user rules: Simplicity is KING - avoid unnecessary complexity
struct PrimaryButtonStyle: ButtonStyle {
    let isEnabled: Bool
    let isSelected: Bool
    
    init(isEnabled: Bool = true, isSelected: Bool = false) {
        self.isEnabled = isEnabled
        self.isSelected = isSelected
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .fontWeight(.bold)
            .font(.system(.title3, design: .rounded))
            .lineLimit(nil)
            .fixedSize(horizontal: false, vertical: true)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(backgroundColor(configuration: configuration).opacity(0.85))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.3),
                                        Color.white.opacity(0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
            )
            .foregroundColor(.white)
            .shadow(color: backgroundColor(configuration: configuration).opacity(0.3), radius: 8, y: 4)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(isEnabled ? 1.0 : 0.6)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
    
    private func backgroundColor(configuration: Configuration) -> Color {
        if !isEnabled {
            return Color.gray
        }
        
        if isSelected {
            return Color.ampedGreen
        }
        
        if configuration.isPressed {
            return Color.ampedGreen.opacity(0.8)
        }
        
        return Color.ampedGreen
    }
}

/// ULTRA-OPTIMIZED questionnaire button style - eliminates lag during interactions
struct QuestionnaireButtonStyle: ButtonStyle {
    let isSelected: Bool
    
    init(isSelected: Bool = false) {
        self.isSelected = isSelected
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 17, weight: .medium, design: .rounded))
            .lineLimit(nil)
            .fixedSize(horizontal: false, vertical: true)
            .multilineTextAlignment(.center)
            // Uniform sizing for all answer buttons, including "Not sure"
            .frame(maxWidth: .infinity, minHeight: 58)
            .padding(.vertical, 16)
            .padding(.horizontal, 20)
            .background(
                // PERFORMANCE FIX: Single background layer, no complex ZStack
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        Color.cardBackground.opacity(
                            configuration.isPressed ? 0.8 : 
                            isSelected ? 0.9 : 1.0
                        )
                    )
                    .overlay(
                        // PERFORMANCE FIX: Simple border without complex gradients
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                Color.ampedGreen.opacity(
                                    isSelected ? 0.7 : 
                                    configuration.isPressed ? 0.4 : 0.2
                                ),
                                lineWidth: isSelected ? 2 : 0.5
                            )
                    )
            )
            .foregroundColor(.white)
            // PERFORMANCE FIX: Minimal shadow for better performance
            .shadow(
                color: Color.ampedGreen.opacity(isSelected ? 0.2 : 0.05),
                radius: isSelected ? 3 : 1,
                x: 0,
                y: 1
            )
            // PERFORMANCE FIX: Subtle scale effect only
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            // PERFORMANCE FIX: Fast easeOut animation instead of complex spring
            .animation(
                .easeOut(duration: 0.1),
                value: configuration.isPressed
            )
            .animation(
                .easeOut(duration: 0.15),
                value: isSelected
            )
    }
}

/// Continue button style for questionnaire - matches standard button height
struct ContinueButtonStyle: ButtonStyle {
    let isEnabled: Bool
    
    init(isEnabled: Bool = true) {
        self.isEnabled = isEnabled
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .fontWeight(.bold)
            .font(.system(.title3, design: .rounded))
            .lineLimit(nil)
            .fixedSize(horizontal: false, vertical: true)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(
                        isEnabled ? Color.ampedGreen : Color.ampedGreen.opacity(0.4)
                    )
            )
            .foregroundColor(.white)
            .shadow(color: Color.black.opacity(0.3), radius: 1, x: 0, y: 1)
            .shadow(color: Color.ampedGreen.opacity(isEnabled ? 0.3 : 0.1), radius: 5, x: 0, y: 2)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(isEnabled ? 1.0 : 0.6)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

/// Secondary button style for less prominent actions
struct SecondaryButtonStyle: ButtonStyle {
    let isEnabled: Bool
    
    init(isEnabled: Bool = true) {
        self.isEnabled = isEnabled
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .fontWeight(.medium)
            .font(.system(.body, design: .rounded))
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.ampedGreen.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.ampedGreen.opacity(0.4),
                                        Color.ampedGreen.opacity(0.2)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                    )
            )
            .foregroundColor(.ampedGreen)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(isEnabled ? 1.0 : 0.6)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

/// ULTRA-OPTIMIZED button style for name input - eliminates expensive rendering
struct UltraOptimizedNameButtonStyle: ButtonStyle {
    let isEnabled: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 17, weight: .medium, design: .rounded))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .padding(.horizontal, 20)
            .background(
                // PERFORMANCE FIX: Single background with state-based opacity
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.ampedGreen.opacity(isEnabled ? (configuration.isPressed ? 0.8 : 1.0) : 0.3))
            )
            .foregroundColor(.white)
            .opacity(isEnabled ? 1.0 : 0.6)
            // PERFORMANCE FIX: Minimal animation, only when necessary
            .scaleEffect(configuration.isPressed && isEnabled ? 0.98 : 1.0)
            .animation(.easeOut(duration: 0.08), value: configuration.isPressed)
    }
}

/// Extension to easily apply consistent button styles
extension View {
    func primaryButtonStyle(isEnabled: Bool = true, isSelected: Bool = false) -> some View {
        self.buttonStyle(PrimaryButtonStyle(isEnabled: isEnabled, isSelected: isSelected))
    }
    
    func questionnaireButtonStyle(isSelected: Bool = false) -> some View {
        self.buttonStyle(QuestionnaireButtonStyle(isSelected: isSelected))
    }
    
    func continueButtonStyle(isEnabled: Bool = true) -> some View {
        self.buttonStyle(ContinueButtonStyle(isEnabled: isEnabled))
    }
    
    func secondaryButtonStyle(isEnabled: Bool = true) -> some View {
        self.buttonStyle(SecondaryButtonStyle(isEnabled: isEnabled))
    }
    
    /// Apply ultra-optimized button style for name input
    func ultraOptimizedNameButtonStyle(isEnabled: Bool = true) -> some View {
        self.buttonStyle(UltraOptimizedNameButtonStyle(isEnabled: isEnabled))
    }
} 