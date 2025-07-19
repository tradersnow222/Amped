import SwiftUI
import StoreKit
import OSLog

/// View for managing app settings and user preferences
struct SettingsView: View {
    @EnvironmentObject private var settingsManager: SettingsManager
    @State private var showResetConfirmation = false
    @State private var showingUpdateHealthProfile = false
    @Environment(\.dismiss) private var dismiss
    
    private let logger = Logger(subsystem: "ai.ampedlife.amped", category: "SettingsView")
    
    var body: some View {
        NavigationView {
            List {
                ProfileSection(showingUpdateHealthProfile: $showingUpdateHealthProfile)
                DisplaySection()
                    .environmentObject(settingsManager)
                PrivacySection(showResetConfirmation: $showResetConfirmation)
                AboutSection()
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Reset All Data?", isPresented: $showResetConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Reset", role: .destructive) {
                    resetAllData()
                }
            } message: {
                Text("This action cannot be undone. All your health data, settings, and preferences will be permanently deleted.")
            }
        }
        .sheet(isPresented: $showingUpdateHealthProfile) {
            UpdateHealthProfileView()
        }
    }
    
    // MARK: - Helper Methods
    
    private func resetAllData() {
        // Reset settings
        settingsManager.resetToDefaults()
        
        // Clear questionnaire data
        QuestionnaireManager().clearAllData()
        
        // Post notification to refresh app
        NotificationCenter.default.post(
            name: NSNotification.Name("AppDataReset"),
            object: nil
        )
        
        dismiss()
    }
}

// MARK: - Profile Section

struct ProfileSection: View {
    @Binding var showingUpdateHealthProfile: Bool
    
    var body: some View {
        Section {
            HStack {
                Image(systemName: "person.crop.circle.fill")
                    .font(.title2)
                    .foregroundColor(.ampedGreen)
                    .frame(width: 40)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Your Profile")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("Manage your health factors")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding(.vertical, 8)
            
            Button {
                showingUpdateHealthProfile = true
            } label: {
                HStack {
                    Image(systemName: "square.and.pencil")
                        .font(.body)
                        .foregroundColor(.ampedGreen)
                        .frame(width: 30)
                    
                    Text("Update Health Profile")
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
            }
            
            NavigationLink {
                BackgroundRefreshSettingsView()
            } label: {
                HStack {
                    Image(systemName: "arrow.clockwise")
                        .font(.body)
                        .foregroundColor(.ampedGreen)
                        .frame(width: 30)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Background App Refresh")
                            .foregroundColor(.primary)
                        Text("Automatic data updates")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
            }
        } header: {
            Text("Profile")
        }
    }
}

// MARK: - Display Section

struct DisplaySection: View {
    @EnvironmentObject var settingsManager: SettingsManager
    
    var body: some View {
        Section {
            Toggle(isOn: $settingsManager.showLifeProjectionAsPercentage) {
                HStack {
                    Image(systemName: "percent")
                        .font(.body)
                        .foregroundColor(.ampedGreen)
                        .frame(width: 30)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Show Life as Percentage")
                            .font(.body)
                        Text("Display remaining life as %")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .tint(.ampedGreen)
            
            Toggle(isOn: $settingsManager.showUnavailableMetrics) {
                HStack {
                    Image(systemName: "eye.slash")
                        .font(.body)
                        .foregroundColor(.ampedGreen)
                        .frame(width: 30)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Show Unavailable Metrics")
                            .font(.body)
                        Text("Display metrics with no data")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .tint(.ampedGreen)
            
            Toggle(isOn: $settingsManager.useMetricSystem) {
                HStack {
                    Image(systemName: "scalemass")
                        .font(.body)
                        .foregroundColor(.ampedGreen)
                        .frame(width: 30)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Use Metric Units")
                            .font(.body)
                        Text("kg, cm instead of lbs, ft")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .tint(.ampedGreen)
        } header: {
            Text("Display")
        }
    }
}

// MARK: - Privacy Section

struct PrivacySection: View {
    @Binding var showResetConfirmation: Bool
    
    var body: some View {
        Section {
            Button(role: .destructive) {
                showResetConfirmation = true
            } label: {
                HStack {
                    Image(systemName: "trash")
                        .font(.body)
                        .foregroundColor(.red)
                        .frame(width: 30)
                    
                    Text("Reset All Data")
                        .foregroundColor(.red)
                }
            }
        } header: {
            Text("Data & Privacy")
        } footer: {
            Text("This will delete all your health data and reset the app to its initial state.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - About Section

struct AboutSection: View {
    var body: some View {
        Section {
            HStack {
                Image(systemName: "info.circle")
                    .font(.body)
                    .foregroundColor(.ampedGreen)
                    .frame(width: 30)
                
                Text("Version")
                Spacer()
                Text("1.0.0")
                    .foregroundColor(.secondary)
            }
        } header: {
            Text("About")
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