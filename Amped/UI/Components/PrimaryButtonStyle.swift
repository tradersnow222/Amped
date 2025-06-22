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

/// Shape for drawing corner-only borders
struct CornerBorder: Shape {
    let cornerRadius: CGFloat
    let cornerLength: CGFloat
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        // Top-left corner
        path.move(to: CGPoint(x: rect.minX + cornerRadius, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX + cornerLength, y: rect.minY))
        path.move(to: CGPoint(x: rect.minX, y: rect.minY + cornerRadius))
        path.addArc(center: CGPoint(x: rect.minX + cornerRadius, y: rect.minY + cornerRadius),
                    radius: cornerRadius,
                    startAngle: .degrees(180),
                    endAngle: .degrees(270),
                    clockwise: false)
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + cornerLength))
        
        // Top-right corner
        path.move(to: CGPoint(x: rect.maxX - cornerLength, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - cornerRadius, y: rect.minY))
        path.addArc(center: CGPoint(x: rect.maxX - cornerRadius, y: rect.minY + cornerRadius),
                    radius: cornerRadius,
                    startAngle: .degrees(270),
                    endAngle: .degrees(0),
                    clockwise: false)
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + cornerLength))
        
        // Bottom-right corner
        path.move(to: CGPoint(x: rect.maxX, y: rect.maxY - cornerLength))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - cornerRadius))
        path.addArc(center: CGPoint(x: rect.maxX - cornerRadius, y: rect.maxY - cornerRadius),
                    radius: cornerRadius,
                    startAngle: .degrees(0),
                    endAngle: .degrees(90),
                    clockwise: false)
        path.addLine(to: CGPoint(x: rect.maxX - cornerLength, y: rect.maxY))
        
        // Bottom-left corner
        path.move(to: CGPoint(x: rect.minX + cornerLength, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX + cornerRadius, y: rect.maxY))
        path.addArc(center: CGPoint(x: rect.minX + cornerRadius, y: rect.maxY - cornerRadius),
                    radius: cornerRadius,
                    startAngle: .degrees(90),
                    endAngle: .degrees(180),
                    clockwise: false)
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - cornerLength))
        
        return path
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
                    .overlay(
                        // Green corner-only outline
                        CornerBorder(cornerRadius: 12, cornerLength: 30)
                            .stroke(
                                Color.ampedGreen.opacity(isSelected ? 0.8 : 0.3),
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
            )
            .foregroundColor(.white)
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