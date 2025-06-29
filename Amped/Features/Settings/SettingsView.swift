import SwiftUI
import StoreKit
import OSLog

/// View for managing app settings and user preferences
struct SettingsView: View {
    @EnvironmentObject private var settingsManager: SettingsManager
    @State private var showResetConfirmation = false
    @State private var isRestoringPurchases = false
    @State private var showRestoreResult = false
    @State private var restoreResultMessage = ""
    @State private var restoreWasSuccessful = false
    
    private let logger = Logger(subsystem: "ai.ampedlife.amped", category: "SettingsView")
    
    var body: some View {
        Form {
            preferencesSection
            notificationsSection
            subscriptionSection
            privacySecuritySection
            supportSection
            aboutSection
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            print("🔧 SettingsView body appeared")
        }
        .alert("Reset Settings", isPresented: $showResetConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                settingsManager.resetToDefaults()
            }
        } message: {
            Text("This will reset all settings to their default values. This action cannot be undone.")
        }
        .alert(restoreWasSuccessful ? "Purchases Restored" : "Restore Failed", isPresented: $showRestoreResult) {
            Button("OK") { }
        } message: {
            Text(restoreResultMessage)
        }
    }
    
    // MARK: - Preferences Section
    
    private var preferencesSection: some View {
        Section {
            // Appearance Setting
            Picker("Appearance", selection: $settingsManager.preferredDisplayMode) {
                ForEach(SettingsManager.DisplayMode.allCases) { mode in
                    Text(mode.displayName).tag(mode)
                }
            }
            .pickerStyle(.menu)
            
            // Units Setting
            Toggle("Use Metric System", isOn: $settingsManager.useMetricSystem)
                .toggleStyle(.switch)
            
            // Metrics Visibility Setting
            Toggle("Show metrics with no data", isOn: $settingsManager.showUnavailableMetrics)
                .toggleStyle(.switch)
            
            // Realtime Countdown Setting
            Toggle("Realtime Countdown", isOn: $settingsManager.showRealtimeCountdown)
                .toggleStyle(.switch)
        } header: {
            Text("PREFERENCES")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Notifications Section
    
    private var notificationsSection: some View {
        Section {
            Toggle("Enable Notifications", isOn: $settingsManager.notificationsEnabled)
                .toggleStyle(.switch)
        } header: {
            Text("NOTIFICATIONS")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Subscription Section
    
    private var subscriptionSection: some View {
        Section {
            // Manage Subscription
            Button {
                openManageSubscriptions()
            } label: {
                HStack {
                    Text("Manage Subscription")
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Restore Purchases (for edge cases only)
            Button {
                restorePurchases()
            } label: {
                HStack {
                    if isRestoringPurchases {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .scaleEffect(0.8)
                    } else {
                        Text("Restore Purchases")
                            .foregroundColor(.primary)
                    }
                    
                    Spacer()
                }
            }
            .disabled(isRestoringPurchases)
        } header: {
            Text("SUBSCRIPTION")
                .font(.caption)
                .foregroundColor(.secondary)
        } footer: {
            Text("Use 'Restore Purchases' if you've switched devices or Apple IDs and need to restore your subscription access.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Privacy & Security Section
    
    private var privacySecuritySection: some View {
        Section {
            NavigationLink(destination: PrivacyPolicyView()) {
                HStack {
                    Text("Privacy Policy")
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        } header: {
            Text("PRIVACY & SECURITY")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Support Section
    
    private var supportSection: some View {
        Section {
            NavigationLink(destination: TermsOfServiceView()) {
                HStack {
                    Text("Terms of Service")
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Button(role: .destructive) {
                showResetConfirmation = true
            } label: {
                HStack {
                    Text("Reset All Settings")
                        .foregroundColor(.red)
                    
                    Spacer()
                }
            }
        } header: {
            Text("SUPPORT")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - About Section
    
    private var aboutSection: some View {
        Section {
            HStack {
                Text("Version")
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("1.0.0")
                    .foregroundColor(.secondary)
            }
        } header: {
            Text("ABOUT")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Helper Methods
    
    private func openManageSubscriptions() {
        Task {
            do {
                // Safely get the window scene
                guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
                    // Fallback to App Store URL if we can't get window scene
                    logger.warning("Could not get window scene, falling back to App Store URL")
                    if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
                        await UIApplication.shared.open(url)
                    }
                    return
                }
                
                try await AppStore.showManageSubscriptions(in: windowScene)
            } catch {
                logger.error("Failed to open manage subscriptions: \(error.localizedDescription)")
                // Fallback to App Store settings
                if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
                    await UIApplication.shared.open(url)
                }
            }
        }
    }
    
    private func restorePurchases() {
        isRestoringPurchases = true
        
        Task {
            do {
                logger.info("Restoring purchases from Settings")
                
                // Sync with App Store
                try await AppStore.sync()
                
                // Check if any subscriptions were restored
                // This is a basic check - you might want to use your StoreKitManager here
                let hasActiveSubscription = await checkForActiveSubscriptions()
                
                await MainActor.run {
                    isRestoringPurchases = false
                    
                    if hasActiveSubscription {
                        restoreWasSuccessful = true
                        restoreResultMessage = "Your subscription has been restored successfully!"
                    } else {
                        restoreWasSuccessful = false
                        restoreResultMessage = "No active subscriptions found to restore. If you believe this is an error, please contact support."
                    }
                    
                    showRestoreResult = true
                }
                
            } catch {
                await MainActor.run {
                    isRestoringPurchases = false
                    restoreWasSuccessful = false
                    restoreResultMessage = "Failed to restore purchases. Please try again or contact support if the issue persists."
                    showRestoreResult = true
                }
                
                logger.error("Failed to restore purchases: \(error.localizedDescription)")
            }
        }
    }
    
    private func checkForActiveSubscriptions() async -> Bool {
        // Check for active subscription transactions
        for await result in Transaction.currentEntitlements {
            switch result {
            case .verified(let transaction):
                // Check if this is a subscription and it's active
                if let expirationDate = transaction.expirationDate {
                    if expirationDate > Date() {
                        return true // Found active subscription
                    }
                } else {
                    // No expiration date means it's active (shouldn't happen for subscriptions though)
                    return true
                }
            case .unverified:
                continue
            }
        }
        return false
    }
}

// MARK: - Privacy Policy View

struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Privacy Policy")
                    .font(.largeTitle)
                    .bold()
                    .foregroundColor(.primary)
                    .padding(.bottom)
                
                Group {
                    Text("Data Collection")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("Amped processes all health data locally on your device. We do not collect, store, or transmit your health data to any external servers.")
                        .foregroundColor(.secondary)
                    
                    Text("With your explicit permission, we may collect anonymous usage data to improve the app experience. This data is never linked to your personal identity.")
                        .foregroundColor(.secondary)
                    
                    Text("Analytics")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("If you opt in to analytics, we collect anonymized information about app usage, features used, and performance metrics. You can disable this at any time in settings.")
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding()
        }
        .navigationTitle("Privacy Policy")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Terms of Service View

struct TermsOfServiceView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Terms of Service")
                    .font(.largeTitle)
                    .bold()
                    .foregroundColor(.primary)
                    .padding(.bottom)
                
                Group {
                    Text("Agreement")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("By using Amped, you agree to these terms of service. The app provides health insights based on scientific research but is not a medical device or a substitute for professional medical advice.")
                        .foregroundColor(.secondary)
                    
                    Text("Limitations of Liability")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("Amped is provided \"as is\" without warranties of any kind. We are not liable for any damages arising from your use of the service.")
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding()
        }
        .navigationTitle("Terms of Service")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    SettingsView()
        .environmentObject(SettingsManager())
} 