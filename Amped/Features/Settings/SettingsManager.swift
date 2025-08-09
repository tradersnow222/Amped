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
        // New: Lifespan display style
        case lifespanDisplayStyle
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

    /// Lifespan projection display style for adaptive UI
    enum LifespanDisplayStyle: String, CaseIterable, Identifiable {
        case auto
        case fullProjection      // Show total lifespan and remaining time
        case impactOnly          // Show time gained/lost from habits only
        case positiveOnly        // Show time gained only

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .auto: return "Auto (recommended)"
            case .fullProjection: return "Full projection"
            case .impactOnly: return "Impact only"
            case .positiveOnly: return "Positive only"
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

    /// User preference for lifespan display style
    @Published var lifespanDisplayStyle: LifespanDisplayStyle {
        didSet {
            UserDefaults.standard.set(lifespanDisplayStyle.rawValue, forKey: SettingKey.lifespanDisplayStyle.rawValue)
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
        self.lifespanDisplayStyle = .auto // Default value
        
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

        // Load lifespan display style
        if let styleRaw = defaults.string(forKey: SettingKey.lifespanDisplayStyle.rawValue),
           let style = LifespanDisplayStyle(rawValue: styleRaw) {
            self.lifespanDisplayStyle = style
        } else {
            self.lifespanDisplayStyle = .auto
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
        
        showUnavailableMetrics = false
        showRealtimeCountdown = true
        // Removed: showLifeProjectionAsPercentage reset
        backgroundRefreshEnabled = true
        lifespanDisplayStyle = .auto
    }

    // MARK: - Resolver
    /// Resolve the effective display style given age, years remaining, and soft cues from questionnaire.
    /// - Parameters:
    ///   - age: User age in years (optional).
    ///   - yearsRemaining: Computed years remaining from projection (optional).
    ///   - stressLevel10: Optional stress level on 1–10 (higher = worse) from questionnaire.
    ///   - deviceTracking: Optional device tracking status (e.g., more engaged users tend to like full view).
    /// - Returns: The effective style to use for UI rendering.
    func effectiveLifespanDisplayStyle(
        age: Double?,
        yearsRemaining: Double?,
        stressLevel10: Double? = nil,
        deviceTracking: String? = nil,
        emotionalSensitivity10: Double? = nil,
        framingComfortScore10: Double? = nil,
        urgencyResponseScore10: Double? = nil
    ) -> LifespanDisplayStyle {
        // If user explicitly chose a non-auto style, honor it.
        switch lifespanDisplayStyle {
        case .fullProjection, .impactOnly, .positiveOnly:
            return lifespanDisplayStyle
        case .auto:
            break
        }

        // Auto: choose based on age brackets and sensitive edge cases
        let ageValue = age ?? 30.0
        if let yearsLeft = yearsRemaining, yearsLeft <= 3.0 {
            // Edge case: very low remaining years → avoid countdown by default
            return .impactOnly
        }

        // Personality cues from questionnaire (soft signals)
        // Build a simple sensitivity index 0..10. Higher => prefers gentler framing.
        let highStress = (stressLevel10 ?? 0) >= 7.0
        let tracksDevice = (deviceTracking ?? "").lowercased().contains("yes")
        let components: [Double] = [
            stressLevel10 ?? -1,
            emotionalSensitivity10 ?? -1,
            framingComfortScore10 ?? -1,
            urgencyResponseScore10 ?? -1
        ].filter { $0 >= 0 }
        let sensitivityIndex = components.isEmpty ? nil : (components.reduce(0, +) / Double(components.count))
        let isSensitive = (sensitivityIndex ?? (highStress ? 8.0 : 0.0)) >= 7.0

        if ageValue < 65 {
            // Younger users: full projection unless sensitive and not tracking → impact only
            if isSensitive && !tracksDevice { return .impactOnly }
            return .fullProjection
        }
        if ageValue < 80 {
            // Mid-older: impact only, but allow full if engaged (tracking) and not sensitive
            if tracksDevice && !isSensitive { return .fullProjection }
            return .impactOnly
        }
        // 80+: positive only by default; if highly engaged and not sensitive, allow impact-only
        if tracksDevice && !isSensitive { return .impactOnly }
        return .positiveOnly
    }
}

// Note: UserDefaults extension is located in Core/Extensions/UserDefaultsExtensions.swift 