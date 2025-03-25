import SwiftUI

/// IMPORTANT: Typography Naming Convention
/// Throughout the app, we use this text style system for consistent typography.
/// Always use: Text("Example").style(.title) instead of .font(.title)
/// This approach provides type safety, better consistency, and easier updates.

/// Typography system for consistent text styling throughout the app
enum AmpedTextStyle {
    // Main type styles
    case largeTitle
    case title
    case title2
    case title3
    case headline
    case subheadline
    case body
    case callout
    case caption
    case caption2
    case footnote
    
    // Custom variants
    case bodyBold
    case bodyMedium
    case bodySecondary
    case headlineBold
    case subheadlineBold
    case cardTitle
    case buttonLabel
    case metricValue
    case percentValue
    case timeIndicator
    
    /// Font weight based on text style
    var weight: Font.Weight {
        switch self {
        case .largeTitle, .title, .title2, .title3, .headlineBold, 
             .subheadlineBold, .bodyBold, .cardTitle, .metricValue, .percentValue:
            return .bold
        case .headline, .buttonLabel:
            return .semibold
        case .bodyMedium, .timeIndicator:
            return .medium
        case .subheadline, .body, .callout, .caption, .caption2, .footnote, .bodySecondary:
            return .regular
        }
    }
    
    /// Font style based on text style
    var style: Font.TextStyle {
        switch self {
        case .largeTitle:
            return .largeTitle
        case .title:
            return .title
        case .title2:
            return .title2
        case .title3:
            return .title3
        case .headline, .headlineBold, .cardTitle:
            return .headline
        case .subheadline, .subheadlineBold:
            return .subheadline
        case .body, .bodyBold, .bodyMedium, .bodySecondary:
            return .body
        case .callout:
            return .callout
        case .caption:
            return .caption
        case .caption2, .timeIndicator:
            return .caption2
        case .footnote:
            return .footnote
        case .buttonLabel:
            return .subheadline
        case .metricValue:
            return .title
        case .percentValue:
            return .title2
        }
    }
    
    /// Design based on text style
    var design: Font.Design {
        switch self {
        case .metricValue, .percentValue, .timeIndicator:
            return .rounded
        default:
            // Using monospaced design for a more robotic, futuristic look
            return .monospaced
        }
    }
    
    /// Text color based on style
    var color: Color {
        switch self {
        case .bodySecondary, .caption, .caption2, .footnote:
            return .secondary
        default:
            return .white
        }
    }
    
    /// Get full font with style, weight, and design
    var font: Font {
        Font.system(style, design: design).weight(weight)
    }
}

/// View extension for applying text styles
extension Text {
    /// Apply Amped text style
    /// - Parameter style: The AmpedTextStyle to apply
    /// - Returns: Text with style applied
    func style(_ style: AmpedTextStyle) -> Text {
        self
            .font(style.font)
            .foregroundColor(style.color)
    }
    
    /// Apply Amped text style with custom color
    /// - Parameters:
    ///   - style: The AmpedTextStyle to apply
    ///   - color: Custom color to override the default style color
    /// - Returns: Text with style and custom color applied
    func style(_ style: AmpedTextStyle, color: Color) -> Text {
        self
            .font(style.font)
            .foregroundColor(color)
    }
}

/// ViewModifier for typography styles
struct TextStyleModifier: ViewModifier {
    let style: AmpedTextStyle
    let customColor: Color?
    
    func body(content: Content) -> some View {
        content
            .font(style.font)
            .foregroundColor(customColor ?? style.color)
    }
}

/// View extension for styling any view with AmpedTextStyle
extension View {
    /// Apply Amped text style to any view (useful for TextField and others)
    /// - Parameter style: The AmpedTextStyle to apply
    /// - Returns: View with text style applied
    func textStyle(_ style: AmpedTextStyle) -> some View {
        self.modifier(TextStyleModifier(style: style, customColor: nil))
    }
    
    /// Apply Amped text style with custom color to any view
    /// - Parameters:
    ///   - style: The AmpedTextStyle to apply
    ///   - color: Custom color to override the default style color
    /// - Returns: View with text style and custom color applied
    func textStyle(_ style: AmpedTextStyle, color: Color) -> some View {
        self.modifier(TextStyleModifier(style: style, customColor: color))
    }
}

/// ViewModifier for futuristic text styling
struct FuturisticTextModifier: ViewModifier {
    let size: CGFloat
    let weight: Font.Weight
    
    init(size: CGFloat = 16, weight: Font.Weight = .regular) {
        self.size = size
        self.weight = weight
    }
    
    func body(content: Content) -> some View {
        content
            .font(.system(size: size, weight: weight, design: .monospaced))
            .foregroundColor(.white)
    }
}

extension View {
    /// Apply futuristic styling to any text view
    /// - Parameters:
    ///   - size: Font size
    ///   - weight: Font weight
    /// - Returns: View with futuristic text styling
    func futuristicText(size: CGFloat = 16, weight: Font.Weight = .regular) -> some View {
        self.modifier(FuturisticTextModifier(size: size, weight: weight))
    }
} 