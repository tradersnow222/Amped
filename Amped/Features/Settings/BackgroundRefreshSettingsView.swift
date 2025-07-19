import SwiftUI
import OSLog

/// Settings view for background refresh status and information
struct BackgroundRefreshSettingsView: View {
    @EnvironmentObject private var backgroundHealthManager: BackgroundHealthManager
    @State private var backgroundStatus: BackgroundStatus?
    
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.amped.Amped", category: "BackgroundRefreshSettingsView")
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            headerSection
            
            if let status = backgroundStatus {
                statusSection(status)
                explanationSection
                troubleshootingSection
            } else {
                loadingSection
            }
        }
        .padding()
        .onAppear {
            loadBackgroundStatus()
        }
        .refreshable {
            loadBackgroundStatus()
        }
    }
    
    // MARK: - View Components
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Background App Refresh")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.ampedGreen)
            
            Text("Keep your health data up-to-date automatically")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
    
    private func statusSection(_ status: BackgroundStatus) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Overall Status
            HStack {
                Image(systemName: status.refreshEnabled ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                    .foregroundColor(status.refreshEnabled ? .green : .orange)
                
                Text("Background Refresh")
                    .fontWeight(.medium)
                
                Spacer()
                
                Text(status.refreshEnabled ? "Enabled" : "Disabled")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(status.refreshEnabled ? Color.green.opacity(0.2) : Color.orange.opacity(0.2))
                    .foregroundColor(status.refreshEnabled ? .green : .orange)
                    .cornerRadius(8)
            }
            
            // Last Update
            if let lastUpdate = status.lastUpdate {
                HStack {
                    Image(systemName: "clock")
                        .foregroundColor(.ampedGreen)
                    
                    Text("Last Update")
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Text(formatRelativeTime(lastUpdate))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Enabled Metrics
            if !status.enabledMetrics.isEmpty {
                HStack {
                    Image(systemName: "heart.fill")
                        .foregroundColor(.ampedRed)
                    
                    Text("Active Metrics")
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Text("\(status.enabledMetrics.count)")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.ampedGreen.opacity(0.2))
                        .foregroundColor(.ampedGreen)
                        .cornerRadius(8)
                }
                
                // Show specific metrics
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 8) {
                    ForEach(status.enabledMetrics.prefix(6), id: \.self) { metric in
                        Text(metric.displayName)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Color.ampedSilver.opacity(0.3))
                            .cornerRadius(6)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var explanationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("How It Works")
                .font(.headline)
                .foregroundColor(.ampedGreen)
            
            VStack(alignment: .leading, spacing: 8) {
                explanationItem(
                    icon: "iphone",
                    title: "Smart Scheduling",
                    description: "iOS automatically schedules updates based on your usage patterns"
                )
                
                explanationItem(
                    icon: "battery.100",
                    title: "Battery Efficient",
                    description: "Updates only run when your device has sufficient battery"
                )
                
                explanationItem(
                    icon: "person.fill.checkmark",
                    title: "User Controlled",
                    description: "You can disable this feature in iOS Settings > General > Background App Refresh"
                )
            }
        }
    }
    
    private var troubleshootingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Troubleshooting")
                .font(.headline)
                .foregroundColor(.ampedYellow)
            
            VStack(alignment: .leading, spacing: 8) {
                if backgroundStatus?.refreshEnabled == false {
                    troubleshootingItem(
                        icon: "gear",
                        title: "Enable Background App Refresh",
                        description: "Go to Settings > General > Background App Refresh and enable it for Amped"
                    )
                }
                
                troubleshootingItem(
                    icon: "bolt.fill",
                    title: "Low Power Mode",
                    description: "Background updates may be limited when Low Power Mode is enabled"
                )
                
                troubleshootingItem(
                    icon: "wifi",
                    title: "Data Settings",
                    description: "Some updates may require Wi-Fi connection to preserve cellular data"
                )
            }
        }
    }
    
    private var loadingSection: some View {
        HStack {
            ProgressView()
                .scaleEffect(0.8)
            
            Text("Loading background refresh status...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
    }
    
    // MARK: - Helper Views
    
    private func explanationItem(icon: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.ampedGreen)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
    
    private func troubleshootingItem(icon: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.ampedYellow)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
    
    // MARK: - Helper Methods
    
    private func loadBackgroundStatus() {
        backgroundStatus = backgroundHealthManager.getBackgroundStatus()
        logger.info("📊 Loaded background status: refresh enabled = \(backgroundStatus?.refreshEnabled ?? false)")
    }
    
    private func formatRelativeTime(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Preview

struct BackgroundRefreshSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            BackgroundRefreshSettingsView()
                .environmentObject(BackgroundHealthManager.shared)
        }
    }
} 