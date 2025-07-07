import Foundation
@preconcurrency import Combine

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
        case showUnavailableMetrics
        case showRealtimeCountdown
        case showLifeProjectionAsPercentage
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
    
    /// Whether to show metrics that have no data available
    @Published var showUnavailableMetrics: Bool {
        didSet {
            UserDefaults.standard.set(showUnavailableMetrics, forKey: SettingKey.showUnavailableMetrics.rawValue)
        }
    }
    
    /// Whether to show realtime countdown with decimal precision
    @Published var showRealtimeCountdown: Bool {
        didSet {
            UserDefaults.standard.set(showRealtimeCountdown, forKey: SettingKey.showRealtimeCountdown.rawValue)
        }
    }
    
    /// Whether to show life projection as percentage instead of years
    @Published var showLifeProjectionAsPercentage: Bool {
        didSet {
            UserDefaults.standard.set(showLifeProjectionAsPercentage, forKey: SettingKey.showLifeProjectionAsPercentage.rawValue)
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
        
        self.showUnavailableMetrics = defaults.bool(forKey: SettingKey.showUnavailableMetrics.rawValue, defaultValue: false)
        self.showRealtimeCountdown = defaults.bool(forKey: SettingKey.showRealtimeCountdown.rawValue, defaultValue: true)
        self.showLifeProjectionAsPercentage = defaults.bool(forKey: SettingKey.showLifeProjectionAsPercentage.rawValue, defaultValue: false)
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
        
        showUnavailableMetrics = false
        showRealtimeCountdown = true
        showLifeProjectionAsPercentage = false
    }
}

// Note: UserDefaults extension is located in Core/Extensions/UserDefaultsExtensions.swift 