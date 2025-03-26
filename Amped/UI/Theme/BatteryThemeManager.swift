import SwiftUI
import Combine

/// Manager for app theming
/// This implements the BatteryThemeManager mentioned in the core services requirements
final class BatteryThemeManager: ObservableObject {
    // MARK: - Theme Properties
    
    /// Primary theme color
    public let primaryColor: Color = Color.ampedGreen
    
    /// Secondary theme color
    public let secondaryColor: Color = Color.ampedSilver
    
    /// Background color for the theme
    public let backgroundColor: Color = Color(.systemBackground)
    
    /// Text color for the theme
    public let textColor: Color = Color(.label)
    
    /// Accent color for the theme
    public let accentColor: Color = Color.ampedGreen
    
    // MARK: - Initialization
    
    init() {
        // Static initialization, no time-based properties
    }
    
    // MARK: - Public Methods
    
    /// Get the appropriate color for a text style
    /// - Parameter style: The text style to get a color for
    /// - Returns: The appropriate color for the text style
    func getThemeColor(for style: AmpedTextStyle) -> Color {
        switch style {
        case .largeTitle, .title, .title2, .title3, .headline, .headlineBold, .cardTitle:
            return primaryColor
        case .metricValue, .percentValue:
            return accentColor
        case .bodySecondary, .caption, .caption2, .footnote:
            return textColor.opacity(0.7)
        default:
            return textColor
        }
    }
}

/// Environment key for accessing the theme manager
struct BatteryThemeManagerKey: EnvironmentKey {
    static let defaultValue = BatteryThemeManager()
}

extension EnvironmentValues {
    var themeManager: BatteryThemeManager {
        get { self[BatteryThemeManagerKey.self] }
        set { self[BatteryThemeManagerKey.self] = newValue }
    }
}

/// View modifier to apply the theme
struct ThemeModifier: ViewModifier {
    @ObservedObject var themeManager: BatteryThemeManager
    
    func body(content: Content) -> some View {
        content
            .accentColor(themeManager.accentColor)
            // Default to light mode, but allow system overrides
            .preferredColorScheme(.light)
    }
}

/// Text modifier for theme-aware text styling
struct ThemedTextModifier: ViewModifier {
    @ObservedObject var themeManager: BatteryThemeManager
    let style: AmpedTextStyle
    
    func body(content: Content) -> some View {
        content
            .font(style.font)
            .foregroundColor(themeManager.getThemeColor(for: style))
    }
}

extension View {
    /// Apply the battery theme to the view
    func withBatteryTheme(_ themeManager: BatteryThemeManager) -> some View {
        self.modifier(ThemeModifier(themeManager: themeManager))
    }
    
    /// Apply themed text style with theme colors
    /// - Parameters:
    ///   - style: The AmpedTextStyle to apply
    ///   - themeManager: The BatteryThemeManager to get colors from
    /// - Returns: View with themed text style
    func themedTextStyle(_ style: AmpedTextStyle, themeManager: BatteryThemeManager) -> some View {
        self.modifier(ThemedTextModifier(themeManager: themeManager, style: style))
    }
} 