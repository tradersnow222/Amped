import SwiftUI
import OSLog

/// View for managing background app refresh settings
struct BackgroundRefreshSettingsView: View {
    @EnvironmentObject private var settingsManager: SettingsManager
    private let logger = Logger(subsystem: "ai.ampedlife.amped", category: "BackgroundRefreshSettings")
    
    var body: some View {
        List {
            Section {
                Toggle("Background App Refresh", isOn: $settingsManager.backgroundRefreshEnabled)
            } footer: {
                Text("When enabled, Amped can update your health data automatically in the background for more accurate battery calculations.")
                    .font(.footnote)
            }
            
            Section("What This Enables") {
                HStack {
                    Image(systemName: "heart.text.square")
                        .font(.title3)
                        .foregroundColor(.red)
                        .frame(width: 30)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Health Data Updates")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text("Automatically fetch new health metrics from HealthKit")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                .padding(.vertical, 2)
                
                HStack {
                    Image(systemName: "battery.100")
                        .font(.title3)
                        .foregroundColor(.green)
                        .frame(width: 30)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Battery Calculations")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text("Update life impact calculations with latest data")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                .padding(.vertical, 2)
                
                HStack {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.title3)
                        .foregroundColor(.blue)
                        .frame(width: 30)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Trend Analysis")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text("Track health trends and patterns over time")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                .padding(.vertical, 2)
            }
            
            Section("Privacy") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Your Privacy is Protected")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("All health data processing happens locally on your device. No data is transmitted to external servers, even with background refresh enabled.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("Background App Refresh")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: settingsManager.backgroundRefreshEnabled) { enabled in
            handleBackgroundRefreshToggle(enabled)
        }
    }
    
    private func handleBackgroundRefreshToggle(_ enabled: Bool) {
        logger.info("Background refresh setting updated: \(enabled)")
        
        if enabled {
            // Start background updates when enabled
            Task {
                let healthKitManager = HealthKitManager.shared
                if healthKitManager.hasAllPermissions || healthKitManager.hasCriticalPermissions {
                    await BackgroundHealthManager.shared.startBackgroundUpdates()
                }
            }
        } else {
            // Note: We don't stop background updates when disabled as iOS will handle scheduling
            // The background tasks will simply not be executed if the user disables background refresh
            logger.info("Background refresh disabled - future background tasks will not execute")
        }
    }
}

#Preview {
    NavigationView {
        BackgroundRefreshSettingsView()
            .environmentObject(SettingsManager())
    }
}
