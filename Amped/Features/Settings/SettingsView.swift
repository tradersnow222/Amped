import SwiftUI

/// View for managing app settings and user preferences
struct SettingsView: View {
    @EnvironmentObject private var settingsManager: SettingsManager
    @Environment(\.dismiss) private var dismiss
    @State private var showResetConfirmation = false
    
    var body: some View {
        NavigationView {
            Form {
                displaySection
                unitSection
                notificationSection
                batterySection
                privacySection
                resetSection
                aboutSection
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .alert("Reset Settings", isPresented: $showResetConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                settingsManager.resetToDefaults()
            }
        } message: {
            Text("This will reset all settings to their default values. This action cannot be undone.")
        }
    }
    
    // MARK: - Display Section
    
    private var displaySection: some View {
        Section(header: Text("Display")) {
            Picker("Appearance", selection: $settingsManager.preferredDisplayMode) {
                ForEach(SettingsManager.DisplayMode.allCases) { mode in
                    Text(mode.displayName).tag(mode)
                }
            }
            .pickerStyle(.menu)
        }
    }
    
    // MARK: - Unit Section
    
    private var unitSection: some View {
        Section(header: Text("Units")) {
            Toggle("Use Metric System", isOn: $settingsManager.useMetricSystem)
                .toggleStyle(.switch)
            Text("Affects how measurements like weight and activity are displayed")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Notification Section
    
    private var notificationSection: some View {
        Section(header: Text("Notifications")) {
            Toggle("Enable Notifications", isOn: $settingsManager.notificationsEnabled)
                .toggleStyle(.switch)
            
            if settingsManager.notificationsEnabled {
                DatePicker("Daily Reminder", selection: $settingsManager.reminderTime, displayedComponents: .hourAndMinute)
            }
        }
    }
    
    // MARK: - Battery Section
    
    private var batterySection: some View {
        Section(header: Text("Battery Visuals")) {
            Toggle("Show Battery Animations", isOn: $settingsManager.showBatteryAnimation)
                .toggleStyle(.switch)
            
            Text("Enables charging and power flow animations")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Privacy Section
    
    private var privacySection: some View {
        Section(header: Text("Privacy")) {
            Toggle("Allow Anonymous Analytics", isOn: $settingsManager.privacyAnalyticsEnabled)
                .toggleStyle(.switch)
            
            Text("Helps us improve the app with anonymous usage data. No personal or health data is ever shared.")
                .font(.caption)
                .foregroundColor(.secondary)
            
            NavigationLink("Privacy Policy") {
                PrivacyPolicyView()
            }
        }
    }
    
    // MARK: - Reset Section
    
    private var resetSection: some View {
        Section {
            Button(role: .destructive) {
                showResetConfirmation = true
            } label: {
                Text("Reset All Settings")
            }
        }
    }
    
    // MARK: - About Section
    
    private var aboutSection: some View {
        Section(header: Text("About")) {
            LabeledContent("Version", value: "1.0.0")
            NavigationLink("Terms of Service") {
                TermsOfServiceView()
            }
        }
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
                    .padding(.bottom)
                
                Group {
                    Text("Data Collection")
                        .font(.headline)
                    
                    Text("Amped processes all health data locally on your device. We do not collect, store, or transmit your health data to any external servers.")
                    
                    Text("With your explicit permission, we may collect anonymous usage data to improve the app experience. This data is never linked to your personal identity.")
                    
                    Text("Analytics")
                        .font(.headline)
                    
                    Text("If you opt in to analytics, we collect anonymized information about app usage, features used, and performance metrics. You can disable this at any time in settings.")
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
                    .padding(.bottom)
                
                Group {
                    Text("Agreement")
                        .font(.headline)
                    
                    Text("By using Amped, you agree to these terms of service. The app provides health insights based on scientific research but is not a medical device or a substitute for professional medical advice.")
                    
                    Text("Limitations of Liability")
                        .font(.headline)
                    
                    Text("Amped is provided \"as is\" without warranties of any kind. We are not liable for any damages arising from your use of the service.")
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