import Foundation
import Combine

/// Manages app settings and user preferences
final class SettingsManager: ObservableObject {
    
    // MARK: - Settings Keys
    
    private enum SettingKey: String {
        case useMetricSystem
        case notificationsEnabled
        case showBatteryAnimation
        case privacyAnalyticsEnabled
        case preferredDisplayMode
        case reminderTime
    }
    
    // MARK: - Enums
    
    /// Display mode preference
    enum DisplayMode: String, CaseIterable, Identifiable {
        case system
        case light
        case dark
        
        var id: String { rawValue }
        
        var displayName: String {
            switch self {
            case .system: return "System"
            case .light: return "Light"
            case .dark: return "Dark"
            }
        }
    }
    
    // MARK: - Published Properties
    
    /// Whether to use metric or imperial units
    @Published var useMetricSystem: Bool {
        didSet {
            UserDefaults.standard.set(useMetricSystem, forKey: SettingKey.useMetricSystem.rawValue)
        }
    }
    
    /// Whether notifications are enabled
    @Published var notificationsEnabled: Bool {
        didSet {
            UserDefaults.standard.set(notificationsEnabled, forKey: SettingKey.notificationsEnabled.rawValue)
        }
    }
    
    /// Whether to show battery charging animations
    @Published var showBatteryAnimation: Bool {
        didSet {
            UserDefaults.standard.set(showBatteryAnimation, forKey: SettingKey.showBatteryAnimation.rawValue)
        }
    }
    
    /// Whether analytics collection is enabled
    @Published var privacyAnalyticsEnabled: Bool {
        didSet {
            UserDefaults.standard.set(privacyAnalyticsEnabled, forKey: SettingKey.privacyAnalyticsEnabled.rawValue)
        }
    }
    
    /// Preferred display mode
    @Published var preferredDisplayMode: DisplayMode {
        didSet {
            UserDefaults.standard.set(preferredDisplayMode.rawValue, forKey: SettingKey.preferredDisplayMode.rawValue)
        }
    }
    
    /// Daily reminder time (if enabled)
    @Published var reminderTime: Date {
        didSet {
            UserDefaults.standard.set(reminderTime.timeIntervalSince1970, forKey: SettingKey.reminderTime.rawValue)
        }
    }
    
    // MARK: - Initialization
    
    init() {
        // Load settings from UserDefaults or use defaults
        let defaults = UserDefaults.standard
        
        self.useMetricSystem = defaults.bool(forKey: SettingKey.useMetricSystem.rawValue, defaultValue: true)
        self.notificationsEnabled = defaults.bool(forKey: SettingKey.notificationsEnabled.rawValue, defaultValue: true)
        self.showBatteryAnimation = defaults.bool(forKey: SettingKey.showBatteryAnimation.rawValue, defaultValue: true)
        self.privacyAnalyticsEnabled = defaults.bool(forKey: SettingKey.privacyAnalyticsEnabled.rawValue, defaultValue: false)
        
        let displayModeString = defaults.string(forKey: SettingKey.preferredDisplayMode.rawValue) ?? DisplayMode.system.rawValue
        self.preferredDisplayMode = DisplayMode(rawValue: displayModeString) ?? .system
        
        let reminderTimeInterval = defaults.double(forKey: SettingKey.reminderTime.rawValue)
        if reminderTimeInterval > 0 {
            self.reminderTime = Date(timeIntervalSince1970: reminderTimeInterval)
        } else {
            // Default to 8:00 AM
            var components = DateComponents()
            components.hour = 8
            components.minute = 0
            self.reminderTime = Calendar.current.date(from: components) ?? Date()
        }
    }
    
    // MARK: - Methods
    
    /// Reset all settings to defaults
    func resetToDefaults() {
        useMetricSystem = true
        notificationsEnabled = true
        showBatteryAnimation = true
        privacyAnalyticsEnabled = false
        preferredDisplayMode = .system
        
        var components = DateComponents()
        components.hour = 8
        components.minute = 0
        reminderTime = Calendar.current.date(from: components) ?? Date()
    }
}

// Note: UserDefaults extension moved to a central utility file to avoid duplication 