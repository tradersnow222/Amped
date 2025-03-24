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
            .accentColor(themeManager.currentTheme.primaryColor)
            .foregroundStyle(themeManager.currentTheme.textColor)
            .background(themeManager.currentTheme.backgroundColor)
    }
}

extension View {
    /// Apply the current battery theme to the view
    func withBatteryTheme(_ themeManager: BatteryThemeManager) -> some View {
        self.modifier(ThemeModifier(themeManager: themeManager))
    }
} 