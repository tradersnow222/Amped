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
        // Removed: showLifeProjectionAsPercentage
        case backgroundRefreshEnabled
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
    
    // Removed: showLifeProjectionAsPercentage setting
    
    /// Whether background app refresh is enabled
    @Published var backgroundRefreshEnabled: Bool {
        didSet {
            UserDefaults.standard.set(backgroundRefreshEnabled, forKey: SettingKey.backgroundRefreshEnabled.rawValue)
        }
    }
    
    // MARK: - Initialization
    
    init() {
        // Load settings from UserDefaults or use defaults
        let defaults = UserDefaults.standard
        
        // Default to imperial for US/UK locales, metric for others
        let locale = Locale.current
        let regionIdentifier = locale.region?.identifier ?? ""
        let defaultToMetric = !["US", "GB", "MM", "LR"].contains(regionIdentifier)
        
        // Set minimal critical settings synchronously
        self.useMetricSystem = defaults.bool(forKey: SettingKey.useMetricSystem.rawValue, defaultValue: defaultToMetric)
        self.notificationsEnabled = true // Default value
        self.showBatteryAnimation = true // Default value
        self.privacyAnalyticsEnabled = false // Default value
        self.preferredDisplayMode = .system // Default value
        self.reminderTime = Date() // Default value
        self.showUnavailableMetrics = false // Default value
        self.showRealtimeCountdown = true // Default value
        // Removed: showLifeProjectionAsPercentage default
        self.backgroundRefreshEnabled = true // Default value - enabled by default
        
        // Defer loading non-critical settings
        Task { @MainActor in
            await loadSettingsAsync()
        }
    }
    
    /// Load non-critical settings asynchronously
    @MainActor
    private func loadSettingsAsync() async {
        let defaults = UserDefaults.standard
        
        // Load actual values from UserDefaults
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
        // Removed: showLifeProjectionAsPercentage load
        self.backgroundRefreshEnabled = defaults.bool(forKey: SettingKey.backgroundRefreshEnabled.rawValue, defaultValue: true)
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
        // Removed: showLifeProjectionAsPercentage reset
        backgroundRefreshEnabled = true
    }
}

// Note: UserDefaults extension is located in Core/Extensions/UserDefaultsExtensions.swift 