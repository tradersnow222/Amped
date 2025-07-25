import SwiftUI
import StoreKit
import OSLog

/// View for managing app settings and user preferences - styled to match Apple Health design
struct SettingsView: View {
    @EnvironmentObject private var settingsManager: SettingsManager
    @State private var showResetConfirmation = false
    @State private var showingCompleteProfileEditor = false
    @Environment(\.dismiss) private var dismiss
    
    private let logger = Logger(subsystem: "ai.ampedlife.amped", category: "SettingsView")
    
    var body: some View {
        NavigationView {
            List {
                ProfileSection(showingCompleteProfileEditor: $showingCompleteProfileEditor)
                
                DisplaySection()
                    .environmentObject(settingsManager)
                
                PrivacySection(showResetConfirmation: $showResetConfirmation)
                
                AboutSection()
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.accentColor)
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
        .sheet(isPresented: $showingCompleteProfileEditor) {
            CompleteProfileEditorView()
        }
    }
    
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
    @Binding var showingCompleteProfileEditor: Bool
    
    var body: some View {
        Section {
                         // Complete Profile Editor
             SettingsRow(
                 icon: "person.text.rectangle",
                 title: "Health Details",
                 subtitle: "Name, age, gender, and health factors",
                 hasChevron: true
             ) {
                 showingCompleteProfileEditor = true
             }
            
            NavigationLink {
                BackgroundRefreshSettingsView()
            } label: {
                SettingsRowContent(
                    icon: "arrow.clockwise",
                    title: "Background App Refresh",
                    subtitle: "Automatic data updates",
                    hasChevron: true
                )
            }
        }
        .sheet(isPresented: $showingCompleteProfileEditor) {
            CompleteProfileEditorView()
        }
    }
}

// MARK: - Display Section

struct DisplaySection: View {
    @EnvironmentObject var settingsManager: SettingsManager
    
    var body: some View {
        Section(header: Text("Features")) {
            SettingsToggleRow(
                icon: "percent",
                title: "Show Life as Percentage",
                subtitle: "Display remaining life as %",
                isOn: $settingsManager.showLifeProjectionAsPercentage
            )
            
            SettingsToggleRow(
                icon: "eye.slash",
                title: "Show Unavailable Metrics",
                subtitle: "Display metrics with no data",
                isOn: $settingsManager.showUnavailableMetrics
            )
            
            SettingsToggleRow(
                icon: "scalemass",
                title: "Use Metric Units",
                subtitle: "kg, cm instead of lbs, ft",
                isOn: $settingsManager.useMetricSystem
            )
        }
    }
}

// MARK: - Privacy Section

struct PrivacySection: View {
    @Binding var showResetConfirmation: Bool
    
    var body: some View {
        Section(header: Text("Privacy"), footer: Text("Your data is encrypted on your device and can only be shared with your permission.").font(.footnote)) {
            NavigationLink {
                PrivacyPolicyView()
            } label: {
                SettingsRowContent(
                    icon: "hand.raised",
                    title: "Privacy Policy",
                    subtitle: nil,
                    hasChevron: true
                )
            }
            
            NavigationLink {
                TermsOfServiceView()
            } label: {
                SettingsRowContent(
                    icon: "doc.text",
                    title: "Terms of Service", 
                    subtitle: nil,
                    hasChevron: true
                )
            }
            
            SettingsRow(
                icon: "trash",
                title: "Reset All Data",
                subtitle: nil,
                isDestructive: true
            ) {
                showResetConfirmation = true
            }
        }
    }
}

// MARK: - About Section

struct AboutSection: View {
    var body: some View {
        Section(header: Text("About")) {
            HStack {
                SettingsRowContent(
                    icon: "info.circle",
                    title: "Version",
                    subtitle: nil,
                    hasChevron: false
                )
                
                Spacer()
                
                Text("1.0.0")
                    .foregroundColor(.secondary)
                    .font(.body)
            }
        }
    }
}

// MARK: - Reusable Components

struct SettingsRow<Content: View>: View {
    let icon: String
    let title: String
    let subtitle: String?
    let hasChevron: Bool
    let isDestructive: Bool
    let action: () -> Void
    
    init(
        icon: String,
        title: String,
        subtitle: String? = nil,
        hasChevron: Bool = false,
        isDestructive: Bool = false,
        @ViewBuilder content: @escaping () -> Content = { EmptyView() },
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.hasChevron = hasChevron
        self.isDestructive = isDestructive
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            SettingsRowContent(
                icon: icon,
                title: title,
                subtitle: subtitle,
                hasChevron: hasChevron,
                isDestructive: isDestructive
            )
        }
        .buttonStyle(.plain)
    }
}

extension SettingsRow where Content == EmptyView {
    init(
        icon: String,
        title: String,
        subtitle: String? = nil,
        hasChevron: Bool = false,
        isDestructive: Bool = false,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.hasChevron = hasChevron
        self.isDestructive = isDestructive
        self.action = action
    }
}

struct SettingsRowContent: View {
    let icon: String
    let title: String
    let subtitle: String?
    let hasChevron: Bool
    let isDestructive: Bool
    
    init(
        icon: String,
        title: String,
        subtitle: String? = nil,
        hasChevron: Bool = false,
        isDestructive: Bool = false
    ) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.hasChevron = hasChevron
        self.isDestructive = isDestructive
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: icon)
                .font(.body)
                .foregroundColor(isDestructive ? .red : .accentColor)
                .frame(width: 24, height: 24)
            
            // Content
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .foregroundColor(isDestructive ? .red : .primary)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Chevron
            if hasChevron {
                                 Image(systemName: "chevron.right")
                     .font(.footnote)
                     .foregroundColor(Color.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}

struct SettingsToggleRow: View {
    let icon: String
    let title: String
    let subtitle: String?
    @Binding var isOn: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: icon)
                .font(.body)
                .foregroundColor(.accentColor)
                .frame(width: 24, height: 24)
            
            // Content
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .foregroundColor(.primary)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Toggle
            Toggle("", isOn: $isOn)
                .labelsHidden()
        }
        .padding(.vertical, 2)
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
        .background(Color(.systemGroupedBackground))
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
        .background(Color(.systemGroupedBackground))
    }
}

#Preview {
    SettingsView()
        .environmentObject(SettingsManager())
} 