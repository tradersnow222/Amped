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
        .scrollContentBackground(.hidden) // Hide default Form background
        .background(Color.clear) // Make Form background transparent
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .withDeepBackground() // Apply app background theme
        .onAppear {
            // Configure navigation bar appearance to match dark theme
            let scrolledAppearance = UINavigationBarAppearance()
            scrolledAppearance.configureWithDefaultBackground()
            scrolledAppearance.backgroundColor = UIColor.black.withAlphaComponent(0.8)
            scrolledAppearance.titleTextAttributes = [.foregroundColor: UIColor.white]
            
            let transparentAppearance = UINavigationBarAppearance()
            transparentAppearance.configureWithTransparentBackground()
            transparentAppearance.titleTextAttributes = [.foregroundColor: UIColor.white]
            
            UINavigationBar.appearance().standardAppearance = scrolledAppearance
            UINavigationBar.appearance().scrollEdgeAppearance = transparentAppearance
            UINavigationBar.appearance().compactAppearance = scrolledAppearance
            
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
            HStack {
                Image(systemName: "paintbrush.fill")
                    .foregroundColor(.ampedYellow)
                    .frame(width: 20)
                
                Picker("Appearance", selection: $settingsManager.preferredDisplayMode) {
                    ForEach(SettingsManager.DisplayMode.allCases) { mode in
                        Text(mode.displayName).tag(mode)
                    }
                }
                .pickerStyle(.menu)
            }
            
            // Units Setting
            HStack {
                Image(systemName: "ruler.fill")
                    .foregroundColor(.ampedYellow)
                    .frame(width: 20)
                
                Toggle("Use Metric System", isOn: $settingsManager.useMetricSystem)
                    .toggleStyle(.switch)
                    .tint(.ampedGreen)
            }
            
            // Metrics Visibility Setting
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(.ampedYellow)
                    .frame(width: 20)
                
                Toggle("Show Unavailable Metrics", isOn: $settingsManager.showUnavailableMetrics)
                    .toggleStyle(.switch)
                    .tint(.ampedGreen)
            }
            
            // Realtime Countdown Setting
            HStack {
                Image(systemName: "timer")
                    .foregroundColor(.ampedYellow)
                    .frame(width: 20)
                
                Toggle("Realtime Countdown", isOn: $settingsManager.showRealtimeCountdown)
                    .toggleStyle(.switch)
                    .tint(.ampedGreen)
            }
        } header: {
            Text("Preferences")
                .foregroundColor(.ampedYellow)
        }
        .listRowBackground(Color.black.opacity(0.6))
    }
    
    // MARK: - Notifications Section
    
    private var notificationsSection: some View {
        Section {
            HStack {
                Image(systemName: "bell.fill")
                    .foregroundColor(.ampedYellow)
                    .frame(width: 20)
                
                Toggle("Enable Notifications", isOn: $settingsManager.notificationsEnabled)
                    .toggleStyle(.switch)
                    .tint(.ampedGreen)
            }
        } header: {
            Text("Notifications")
                .foregroundColor(.ampedYellow)
        }
        .listRowBackground(Color.black.opacity(0.6))
    }
    
    // MARK: - Subscription Section
    
    private var subscriptionSection: some View {
        Section {
            // Manage Subscription
            Button {
                openManageSubscriptions()
            } label: {
                HStack {
                    Image(systemName: "creditcard.fill")
                        .foregroundColor(.ampedYellow)
                        .frame(width: 20)
                    
                    Text("Manage Subscription")
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Image(systemName: "arrow.up.right")
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
                            .progressViewStyle(CircularProgressViewStyle(tint: .ampedYellow))
                            .scaleEffect(0.8)
                            .frame(width: 20)
                    } else {
                        Image(systemName: "arrow.clockwise.circle.fill")
                            .foregroundColor(.ampedYellow)
                            .frame(width: 20)
                    }
                    
                    Text("Restore Purchases")
                        .foregroundColor(.primary)
                    
                    Spacer()
                }
            }
            .disabled(isRestoringPurchases)
        } header: {
            Text("Subscription")
                .foregroundColor(.ampedYellow)
        } footer: {
            Text("Use 'Restore Purchases' if you've switched devices or Apple IDs and need to restore your subscription access.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .listRowBackground(Color.black.opacity(0.6))
    }
    
    // MARK: - Privacy & Security Section
    
    private var privacySecuritySection: some View {
        Section {
            NavigationLink(destination: PrivacyPolicyView()) {
                HStack {
                    Image(systemName: "hand.raised.fill")
                        .foregroundColor(.ampedYellow)
                        .frame(width: 20)
                    
                    Text("Privacy Policy")
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        } header: {
            Text("Privacy & Security")
                .foregroundColor(.ampedYellow)
        }
        .listRowBackground(Color.black.opacity(0.6))
    }
    
    // MARK: - Support Section
    
    private var supportSection: some View {
        Section {
            NavigationLink(destination: TermsOfServiceView()) {
                HStack {
                    Image(systemName: "doc.text.fill")
                        .foregroundColor(.ampedYellow)
                        .frame(width: 20)
                    
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
                    Image(systemName: "arrow.clockwise")
                        .foregroundColor(.ampedRed)
                        .frame(width: 20)
                    
                    Text("Reset All Settings")
                        .foregroundColor(.ampedRed)
                    
                    Spacer()
                }
            }
        } header: {
            Text("Support")
                .foregroundColor(.ampedYellow)
        }
        .listRowBackground(Color.black.opacity(0.6))
    }
    
    // MARK: - About Section
    
    private var aboutSection: some View {
        Section {
            HStack {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(.ampedYellow)
                    .frame(width: 20)
                
                Text("Version")
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("1.0.0")
                    .foregroundColor(.secondary)
            }
        } header: {
            Text("About")
                .foregroundColor(.ampedYellow)
        }
        .listRowBackground(Color.black.opacity(0.6))
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
                    .foregroundColor(.ampedGreen)
                    .padding(.bottom)
                
                Group {
                    Text("Data Collection")
                        .font(.headline)
                        .foregroundColor(.ampedYellow)
                    
                    Text("Amped processes all health data locally on your device. We do not collect, store, or transmit your health data to any external servers.")
                        .foregroundColor(.primary)
                    
                    Text("With your explicit permission, we may collect anonymous usage data to improve the app experience. This data is never linked to your personal identity.")
                        .foregroundColor(.primary)
                    
                    Text("Analytics")
                        .font(.headline)
                        .foregroundColor(.ampedYellow)
                    
                    Text("If you opt in to analytics, we collect anonymized information about app usage, features used, and performance metrics. You can disable this at any time in settings.")
                        .foregroundColor(.primary)
                }
                
                Spacer()
            }
            .padding()
        }
        .background(Color.clear)
        .withDeepBackground()
        .navigationTitle("Privacy Policy")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // Configure navigation bar appearance to match dark theme
            let scrolledAppearance = UINavigationBarAppearance()
            scrolledAppearance.configureWithDefaultBackground()
            scrolledAppearance.backgroundColor = UIColor.black.withAlphaComponent(0.8)
            scrolledAppearance.titleTextAttributes = [.foregroundColor: UIColor.white]
            
            let transparentAppearance = UINavigationBarAppearance()
            transparentAppearance.configureWithTransparentBackground()
            transparentAppearance.titleTextAttributes = [.foregroundColor: UIColor.white]
            
            UINavigationBar.appearance().standardAppearance = scrolledAppearance
            UINavigationBar.appearance().scrollEdgeAppearance = transparentAppearance
            UINavigationBar.appearance().compactAppearance = scrolledAppearance
        }
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
                    .foregroundColor(.ampedGreen)
                    .padding(.bottom)
                
                Group {
                    Text("Agreement")
                        .font(.headline)
                        .foregroundColor(.ampedYellow)
                    
                    Text("By using Amped, you agree to these terms of service. The app provides health insights based on scientific research but is not a medical device or a substitute for professional medical advice.")
                        .foregroundColor(.primary)
                    
                    Text("Limitations of Liability")
                        .font(.headline)
                        .foregroundColor(.ampedYellow)
                    
                    Text("Amped is provided \"as is\" without warranties of any kind. We are not liable for any damages arising from your use of the service.")
                        .foregroundColor(.primary)
                }
                
                Spacer()
            }
            .padding()
        }
        .background(Color.clear)
        .withDeepBackground()
        .navigationTitle("Terms of Service")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // Configure navigation bar appearance to match dark theme
            let scrolledAppearance = UINavigationBarAppearance()
            scrolledAppearance.configureWithDefaultBackground()
            scrolledAppearance.backgroundColor = UIColor.black.withAlphaComponent(0.8)
            scrolledAppearance.titleTextAttributes = [.foregroundColor: UIColor.white]
            
            let transparentAppearance = UINavigationBarAppearance()
            transparentAppearance.configureWithTransparentBackground()
            transparentAppearance.titleTextAttributes = [.foregroundColor: UIColor.white]
            
            UINavigationBar.appearance().standardAppearance = scrolledAppearance
            UINavigationBar.appearance().scrollEdgeAppearance = transparentAppearance
            UINavigationBar.appearance().compactAppearance = scrolledAppearance
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(SettingsManager())
} 