import SwiftUI
import Combine

/// Manager for time-based app theming that changes the color scheme based on time of day
/// This implements the BatteryThemeManager mentioned in the core services requirements
final class BatteryThemeManager: ObservableObject {
    // MARK: - Theme Types
    
    /// Time-based theme types
    enum ThemeType: String, CaseIterable {
        case morning
        case midday
        case afternoon
        case evening
        case night
        
        /// Get the appropriate theme based on the current hour
        static func forCurrentTime() -> ThemeType {
            let hour = Calendar.current.component(.hour, from: Date())
            
            switch hour {
            case 5..<10:  // 5:00 AM - 9:59 AM
                return .morning
            case 10..<14: // 10:00 AM - 1:59 PM
                return .midday
            case 14..<18: // 2:00 PM - 5:59 PM
                return .afternoon
            case 18..<22: // 6:00 PM - 9:59 PM
                return .evening
            default:      // 10:00 PM - 4:59 AM
                return .night
            }
        }
        
        /// Primary color for the theme
        var primaryColor: Color {
            switch self {
            case .morning:
                return Color.ampedMorning
            case .midday:
                return Color.ampedMidday
            case .afternoon:
                return Color.ampedAfternoon
            case .evening:
                return Color.ampedEvening
            case .night:
                return Color.ampedNight
            }
        }
        
        /// Secondary color for the theme
        var secondaryColor: Color {
            switch self {
            case .morning:
                return Color.ampedMorningSecondary
            case .midday:
                return Color.ampedMiddaySecondary
            case .afternoon:
                return Color.ampedAfternoonSecondary
            case .evening:
                return Color.ampedEveningSecondary
            case .night:
                return Color.ampedNightSecondary
            }
        }
        
        /// Background color for the theme
        var backgroundColor: Color {
            switch self {
            case .morning, .midday, .afternoon:
                return Color(.systemBackground)
            case .evening:
                return Color(.systemBackground).opacity(0.95)
            case .night:
                return Color(.systemBackground).opacity(0.9)
            }
        }
        
        /// Text color for the theme
        var textColor: Color {
            switch self {
            case .morning, .midday, .afternoon:
                return Color(.label)
            case .evening, .night:
                return Color(.label).opacity(0.95)
            }
        }
        
        /// Accent color for the theme
        var accentColor: Color {
            switch self {
            case .morning, .midday:
                return Color.ampedGreen
            case .afternoon:
                return Color.ampedYellow
            case .evening, .night:
                return Color.ampedSilver
            }
        }
    }
    
    // MARK: - Properties
    
    @Published var currentTheme: ThemeType
    private var themeUpdateTimer: AnyCancellable?
    
    // MARK: - Initialization
    
    init() {
        self.currentTheme = ThemeType.forCurrentTime()
        scheduleThemeUpdates()
    }
    
    // MARK: - Public Methods
    
    /// Manually update the theme
    func updateTheme() {
        currentTheme = ThemeType.forCurrentTime()
    }
    
    /// Get the appropriate color for a text style in the current theme
    /// - Parameter style: The text style to get a color for
    /// - Returns: The appropriate color for the text style in the current theme
    func getThemeColor(for style: AmpedTextStyle) -> Color {
        switch style {
        case .largeTitle, .title, .title2, .title3, .headline, .headlineBold, .cardTitle:
            return currentTheme.primaryColor
        case .metricValue, .percentValue:
            return currentTheme.accentColor
        case .bodySecondary, .caption, .caption2, .footnote:
            return currentTheme.textColor.opacity(0.7)
        default:
            return currentTheme.textColor
        }
    }
    
    // MARK: - Private Methods
    
    /// Schedule regular theme updates
    private func scheduleThemeUpdates() {
        // Cancel any existing timer
        themeUpdateTimer?.cancel()
        
        // Create a timer that fires every hour
        themeUpdateTimer = Timer.publish(every: 3600, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updateTheme()
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

/// View modifier to apply the current theme
struct ThemeModifier: ViewModifier {
    @ObservedObject var themeManager: BatteryThemeManager
    
    func body(content: Content) -> some View {
        content
            // Removed background setting since we're using DeepBackground image
            .accentColor(themeManager.currentTheme.accentColor)
            .environment(\.colorScheme, colorSchemeForCurrentTheme)
    }
    
    /// Determine color scheme based on current theme
    private var colorSchemeForCurrentTheme: ColorScheme {
        switch themeManager.currentTheme {
        case .morning, .midday, .afternoon:
            return .light
        case .evening, .night:
            return .dark
        }
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
    /// Apply the current battery theme to the view
    func withBatteryTheme(_ themeManager: BatteryThemeManager) -> some View {
        self.modifier(ThemeModifier(themeManager: themeManager))
    }
    
    /// Apply themed text style with current theme colors
    /// - Parameters:
    ///   - style: The AmpedTextStyle to apply
    ///   - themeManager: The BatteryThemeManager to get colors from
    /// - Returns: View with themed text style
    func themedTextStyle(_ style: AmpedTextStyle, themeManager: BatteryThemeManager) -> some View {
        self.modifier(ThemedTextModifier(themeManager: themeManager, style: style))
    }
} 