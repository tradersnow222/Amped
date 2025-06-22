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
            .font(.system(.title3, design: .default))
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



/// Sleek, glass-themed button style for questionnaire - matches health metric cards
struct QuestionnaireButtonStyle: ButtonStyle {
    let isSelected: Bool
    
    init(isSelected: Bool = false) {
        self.isSelected = isSelected
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 17, weight: .medium, design: .rounded))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .padding(.horizontal, 20)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.cardBackground)
            )
            .foregroundColor(.white)
            .overlay(
                // Subtle glow effect instead of harsh corner borders
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        Color.ampedGreen.opacity(isSelected ? 0.6 : 0.2),
                        lineWidth: isSelected ? 1.5 : 0.5
                    )
            )
            .shadow(
                color: Color.ampedGreen.opacity(isSelected ? 0.4 : 0.1),
                radius: isSelected ? 8 : 4,
                x: 0,
                y: 0
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
            .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

/// Compact continue button style for questionnaire
struct ContinueButtonStyle: ButtonStyle {
    let isEnabled: Bool
    
    init(isEnabled: Bool = true) {
        self.isEnabled = isEnabled
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 17, weight: .semibold, design: .rounded))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .padding(.horizontal, 24)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(
                        isEnabled ? Color.ampedGreen : Color.ampedGreen.opacity(0.4)
                    )
            )
            .foregroundColor(.white)
            .shadow(color: Color.ampedGreen.opacity(isEnabled ? 0.3 : 0.1), radius: 6, y: 3)
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
            .font(.system(.body, design: .default))
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
} 