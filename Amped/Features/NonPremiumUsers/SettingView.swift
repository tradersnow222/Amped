//
//  SettingView.swift
//  Amped
//
//  Created by Shadeem Kazmi on 03/11/2025.
//

import SwiftUI

struct SettingView: View {
    // Assuming you have a way to dismiss this view, e.g., if it's a sheet
    @Environment(\.dismiss) var dismiss
    
    // Placeholder for user name and initial letters
    @State private var userName: String = "Adam John"
    @State private var userInitials: String = "AJ"
    
    // State for navigation/actions
    @State private var showingNotificationSettings: Bool = false
    @State private var showingFeedbackSurvey: Bool = false
    @State private var showingDeleteAccountConfirmation: Bool = false
    @State private var showingLogoutConfirmation: Bool = false
    
    // Gradient for the selected tab in the bottom bar (reused from previous examples)
    let selectedTabGradient = LinearGradient(
        gradient: Gradient(colors: [Color(hex: "318AFC"), Color(hex: "18EF47")]),
        startPoint: .leading,
        endPoint: .trailing
    )
    
    var body: some View {
        ZStack {
            // Dark background for the entire screen
            Color.black.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                // Custom Navigation Bar
                customNavigationBar
                    .padding(.bottom, 20) // Spacing below nav bar
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 30) {
                        // User Profile Section
                        userProfileSection
                        
                        // Additional Settings Section
                        additionalSettingsSection
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 80) // Space for the bottom tab bar
                }
                
                Spacer() // Pushes content up, but ScrollView handles full content
                
                // Custom Bottom Tab Bar
                // You would pass the actual selectedTab state from a parent view
//                CustomBottomTabBar(selectedTab: 4, selectedTabGradient: selectedTabGradient)
            }
        }
        // Sheets or fullScreenCovers for sub-settings
        .sheet(isPresented: $showingNotificationSettings) {
            // NotificationSettingsView() // Create this view if needed
            Text("Notification Settings View Placeholder")
                .preferredColorScheme(.dark)
        }
        .sheet(isPresented: $showingFeedbackSurvey) {
            // FeedbackSurveyView() // Create this view if needed
            Text("Feedback Survey View Placeholder")
                .preferredColorScheme(.dark)
        }
        .alert("Delete Account", isPresented: $showingDeleteAccountConfirmation) {
            Button("Delete", role: .destructive) { /* Perform delete action */ }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to delete your account? This action cannot be undone.")
        }
        .alert("Log Out", isPresented: $showingLogoutConfirmation) {
            Button("Log Out", role: .destructive) { /* Perform logout action */ }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to log out?")
        }
    }
    
    // MARK: - Subviews
    
    private var customNavigationBar: some View {
        HStack {
            Button(action: {
                dismiss() // Dismisses the current sheet/view
            }) {
                Image(systemName: "arrow.left")
                    .font(.title2)
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            Text("Settings")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            Spacer()
            
            // Placeholder to balance the layout if no right button
            Rectangle()
                .fill(Color.clear)
                .frame(width: 25, height: 25)
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
    }
    
    private var userProfileSection: some View {
            VStack(alignment: .leading) {
                // ⭐️ Wrap the entire row in a NavigationLink
                NavigationLink(destination: EditUserProfileView()) {
                    HStack {
                        // Circular initials avatar
                        Text(userInitials)
                            .font(.headline).fontWeight(.bold).foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(Color.gray.opacity(0.4)).clipShape(Circle())
                        
                        Text(userName)
                            .font(.title3).fontWeight(.medium).foregroundColor(.white)
                        
                        Spacer()
                        
                        // The gear icon is now just a visual element inside the link
                        Image(systemName: "gearshape")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                }
                // Use PlainButtonStyle to prevent the link from getting a default blue background
                .buttonStyle(PlainButtonStyle())
                .padding(12)
                .background(Color.gray.opacity(0.2))
                .cornerRadius(12)
            }
        }
    
//    private var userProfileSection: some View {
//        VStack(alignment: .leading) {
//            HStack {
//                // Circular initials avatar
//                Text(userInitials)
//                    .font(.headline)
//                    .fontWeight(.bold)
//                    .foregroundColor(.white)
//                    .frame(width: 44, height: 44)
//                    .background(Color.gray.opacity(0.4))
//                    .clipShape(Circle())
//                
//                Text(userName)
//                    .font(.title3)
//                    .fontWeight(.medium)
//                    .foregroundColor(.white)
//                
//                Spacer()
//                
//                // Gear icon button
//                Button(action: {
//                    // Action for profile settings
//                }) {
//                    Image(systemName: "gearshape")
//                        .font(.title2)
//                        .foregroundColor(.white)
//                }
//            }
//            .padding(12)
//            .background(Color.gray.opacity(0.2))
//            .cornerRadius(12)
//        }
//    }
    
    private var additionalSettingsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Additional")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.gray)
                .padding(.leading, 8)
            
            VStack(spacing: 0) { // No spacing between rows, handled by padding
                SettingRow(icon: "bell.badge.fill", title: "Notification settings", action: { showingNotificationSettings = true })
                Divider().background(Color.gray.opacity(0.3)).padding(.horizontal, 16)
                SettingRow(icon: "star.fill", title: "Rate the app", action: { /* Open App Store */ })
                Divider().background(Color.gray.opacity(0.3)).padding(.horizontal, 16)
                SettingRow(icon: "doc.text.fill", title: "Feedback survey", action: { showingFeedbackSurvey = true })
                Divider().background(Color.gray.opacity(0.3)).padding(.horizontal, 16)
                SettingRow(icon: "trash.fill", title: "Delete account", isDestructive: true, action: { showingDeleteAccountConfirmation = true })
                Divider().background(Color.gray.opacity(0.3)).padding(.horizontal, 16)
                SettingRow(icon: "arrow.right.square.fill", title: "Logout", isDestructive: true, action: { showingLogoutConfirmation = true })
            }
            .background(Color.gray.opacity(0.2))
            .cornerRadius(12)
        }
    }
    
    struct SettingRow: View {
        let icon: String
        let title: String
        var isDestructive: Bool = false
        let action: () -> Void
        
        var body: some View {
            Button(action: action) {
                HStack {
                    Image(systemName: icon)
                        .font(.subheadline)
                        .foregroundColor(isDestructive ? .red : .white.opacity(0.8))
                        .frame(width: 25) // Fixed width for alignment
                    
                    Text(title)
                        .font(.body)
                        .foregroundColor(isDestructive ? .red : .white)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding(.vertical, 14)
                .padding(.horizontal, 16)
            }
        }
    }
}
