//
//  SettingView.swift
//  Amped
//
//  Created by Shadeem Kazmi on 03/11/2025.
//

import SwiftUI

struct SettingView: View {
    @Environment(\.dismiss) private var dismiss
    
    // Alerts
    @State private var showingDeleteAccountConfirmation: Bool = false
    @State private var showingLogoutConfirmation: Bool = false
    
    // Feedback dialog state
    @State private var showFeedbackDialog: Bool = false
    @State private var feedbackText: String = ""
    
    // Row background/stroke to match the screenshot
    private var rowBackground: LinearGradient {
        LinearGradient(
            colors: [
                Color.white.opacity(0.08),
                Color.white.opacity(0.05)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    private var rowStroke: Color { Color.white.opacity(0.18) }
    
    var body: some View {
        ZStack {
            // Full-screen background gradient like the screenshot
            LinearGradient.customBlueToDarkGray
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                header
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 22) {
                        profileCard
                        additionalSection
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 24)
                }
            }
        }
        .navigationBarHidden(true)
        .alert("Delete Account", isPresented: $showingDeleteAccountConfirmation) {
            Button("Delete", role: .destructive) {
                // TODO: Perform delete action
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to delete your account? This action cannot be undone.")
        }
        .alert("Log Out", isPresented: $showingLogoutConfirmation) {
            Button("Log Out", role: .destructive) {
                // TODO: Perform logout action
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to log out?")
        }
        // Attach the reusable feedback dialog overlay
        .feedbackDialog(
            isPresented: $showFeedbackDialog,
            text: $feedbackText,
            title: "Please share your feedback with us.",
            onSubmit: { message in
                // Send to your backend/analytics here
                print("Settings feedback submitted: \(message)")
                // Clear after submit
                feedbackText = ""
            },
            onCancel: {
                // Optional: track dismiss
            }
        )
    }
    
    // MARK: - Header
    
    private var header: some View {
        ZStack {
            HStack {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .foregroundStyle(.white)
                        .font(.system(size: 20, weight: .semibold))
                        .padding(12)
                }
                Spacer()
            }
            
            Text("Settings")
                .foregroundStyle(.white)
                .font(.system(size: 18, weight: .semibold))
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 12)
    }
    
    // MARK: - Profile card
    
    private var profileCard: some View {
        NavigationLink {
            // Navigate to MascotNamingView from Settings
            // It will pre-populate from UserDefaults and save back on Continue.
            MascotNamingView(isFromSettings: true)
                .navigationBarBackButtonHidden(false)
        } label: {
            HStack(spacing: 12) {
                // Left rounded “chip” with initials
                Text(ProfileImageManager.shared.getInitials())
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(Color.white.opacity(0.15), in: Circle())
                    .overlay(Circle().stroke(rowStroke, lineWidth: 1))
                
                Text(ProfileImageManager.shared.getUserName())
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                
                Spacer()
                
                // Gear in a subtle rounded background
                Image(systemName: "gearshape")
                    .foregroundColor(.white)
                    .font(.system(size: 18, weight: .semibold))
                    .padding(8)
                    .background(Color.white.opacity(0.10), in: Circle())
                    .overlay(Circle().stroke(rowStroke, lineWidth: 1))
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(rowBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(rowStroke, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Additional Section
    
    private var additionalSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Additional")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.9))
                .padding(.leading, 4)
            
            VStack(spacing: 14) {
                // Subscription Paywall
                NavigationLink {
                    SubscriptionView(isFromOnboarding: false) { _ in }
                        .navigationBarBackButtonHidden(true)
                } label: {
                    SettingRowCard(icon: "creditcard", title: "Subscription Paywall", rowBackground: rowBackground, rowStroke: rowStroke)
                }
                .buttonStyle(.plain)
                
                // Notification settings (push, no sheet)
                NavigationLink {
                    NotificationSettingsView()
                        .navigationBarBackButtonHidden(true)
                } label: {
                    SettingRowCard(icon: "bell.badge.fill", title: "Notification settings", rowBackground: rowBackground, rowStroke: rowStroke)
                }
                .buttonStyle(.plain)
                
                // Rate the app
                NavigationLink {
                    RateAppView()
                        .navigationBarBackButtonHidden(true)
                } label: {
                    SettingRowCard(icon: "star.fill", title: "Rate the app", rowBackground: rowBackground, rowStroke: rowStroke)
                }
                .buttonStyle(.plain)
                
                // Feedback survey (opens dialog)
                Button {
                    showFeedbackDialog = true
                } label: {
                    SettingRowCard(icon: "doc.text.fill", title: "Feedback survey", rowBackground: rowBackground, rowStroke: rowStroke)
                }
                .buttonStyle(.plain)
                
                // Delete account (destructive)
                Button {
                    showingDeleteAccountConfirmation = true
                } label: {
                    SettingRowCard(icon: "trash.fill", title: "Delete account", rowBackground: rowBackground, rowStroke: rowStroke, isDestructive: true)
                }
                .buttonStyle(.plain)
                
                // Logout (destructive)
                Button {
                    showingLogoutConfirmation = true
                } label: {
                    SettingRowCard(icon: "arrow.right.square.fill", title: "Logout", rowBackground: rowBackground, rowStroke: rowStroke, isDestructive: true)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Row Card

private struct SettingRowCard: View {
    let icon: String
    let title: String
    let rowBackground: LinearGradient
    let rowStroke: Color
    var isDestructive: Bool = false
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(isDestructive ? .red : .white.opacity(0.9))
                .frame(width: 20, height: 20)
                .background(Color.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(rowStroke, lineWidth: 1)
                )
            
            Text(title)
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(isDestructive ? .red : .white)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white.opacity(0.6))
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(rowBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(rowStroke, lineWidth: 1)
                )
        )
    }
}

struct SettingView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SettingView()
        }
        .environmentObject(AppState())
    }
}
