//
//  SettingView.swift
//  Amped
//
//  Created by Shadeem Kazmi on 03/11/2025.
//

import SwiftUI
import OSLog

struct SettingView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appState: AppState
    @ObservedObject private var profileManager = ProfileImageManager.shared
    
    // Alerts (now used to drive custom dialogs instead of system .alert)
    @State private var showingDeleteAccountConfirmation: Bool = false
    @State private var showingLogoutConfirmation: Bool = false
    @State private var showOnboardingFlow: Bool = false
    
    // Feedback dialog state
    @State private var showFeedbackDialog: Bool = false
    @State private var feedbackText: String = ""
    
    // Local logger
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.amped.Amped", category: "SettingView")
    
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
            
            // MARK: - Custom Confirm Dialogs Overlay
            if showingDeleteAccountConfirmation || showingLogoutConfirmation {
                // Dimmed backdrop
                Color.black.opacity(0.75)
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .onTapGesture {
                        // Tap outside to cancel
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.95)) {
                            showingDeleteAccountConfirmation = false
                            showingLogoutConfirmation = false
                        }
                    }
                
                // Dialog content
                Group {
                    if showingDeleteAccountConfirmation {
                        CustomDialogView(
                            emoji: "crying_face",
                            message: "Are you sure you want to delete your account and live a shorter life?",
                            primaryTitle: "Delete",
                            secondaryTitle: "Cancel",
                            primaryIsDestructive: true,
                            onPrimary: {
                                withAnimation(.spring(response: 0.25, dampingFraction: 0.95)) {
                                    showingDeleteAccountConfirmation = false
                                }
                                performFullDataWipe()
                            },
                            onCancel: {
                                withAnimation(.spring(response: 0.25, dampingFraction: 0.95)) {
                                    showingDeleteAccountConfirmation = false
                                }
                            }
                        )
                    }
                    if showingLogoutConfirmation {
                        CustomDialogView(
                            emoji: "disappointed_face",
                            message: "Are you sure you want to logout?",
                            primaryTitle: "Logout",
                            secondaryTitle: "Cancel",
                            primaryIsDestructive: false,
                            onPrimary: {
                                withAnimation(.spring(response: 0.25, dampingFraction: 0.95)) {
                                    showingLogoutConfirmation = false
                                }
                                performLogout()
                            },
                            onCancel: {
                                withAnimation(.spring(response: 0.25, dampingFraction: 0.95)) {
                                    showingLogoutConfirmation = false
                                }
                            }
                        )
                    }
                }
                .transition(.scale.combined(with: .opacity))
                .zIndex(10)
            }
        }
        .navigationBarHidden(true)
        .fullScreenCover(isPresented: $showOnboardingFlow) {
            OnboardingFlow(isFromSettings: showOnboardingFlow).environmentObject(appState)
        }
        // Removed system .alert modifiers and replaced with custom overlay above
        // Attach the reusable feedback dialog overlay
        .feedbackDialog(
            isPresented: $showFeedbackDialog,
            text: $feedbackText,
            title: "Please share your feedback with us.",
            onSubmit: { message in

                // Send feedback via email
                FeedbackEmailHelper.shared.sendFeedbackEmail(body: message)

                // Optional: also send to backend if you want
                print("Settings feedback submitted: \(message)")

                // Clear after submit
                feedbackText = ""
            },
            onCancel: {
                // Optional: track dismiss
            }
        )
        .animation(.easeInOut(duration: 0.2), value: showingDeleteAccountConfirmation)
        .animation(.easeInOut(duration: 0.2), value: showingLogoutConfirmation)
    }
    
    // MARK: - Header
    
    private var header: some View {
        ZStack {
            HStack {
                Button {
                    dismiss()
                } label: {
                    Image("backIcon")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
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
            // Navigate to EditProfileView from Settings
            EditProfileView().navigationBarBackButtonHidden(true)
        } label: {
            HStack(spacing: 12) {
                if let profileImage = profileManager.profileImage {
                    Image(uiImage: profileImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                } else {
                    // Left rounded “chip” with initials
                    Text(ProfileImageManager.shared.getInitials())
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(width: 40, height: 40)
                        .background(Color.white.opacity(0.15), in: Circle())
                        .overlay(Circle().stroke(rowStroke, lineWidth: 1))
                }
                
                Text(ProfileImageManager.shared.getUserName())
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                
                Spacer()
                
                // Gear in a subtle rounded background
                Image(systemName: "gearshape")
                    .foregroundColor(.white)
                    .font(.system(size: 18, weight: .semibold))
                    .padding(8)
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
                NavigationLink {
                    FeedbackSurveyView()
                        .navigationBarBackButtonHidden(true)
//                    showFeedbackDialog = true
                } label: {
                    SettingRowCard(icon: "doc.text.fill", title: "Feedback survey", rowBackground: rowBackground, rowStroke: rowStroke)
                }
                .buttonStyle(.plain)
                
                // Delete account (destructive) -> custom dialog
                Button {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.95)) {
                        showingDeleteAccountConfirmation = true
                    }
                } label: {
                    SettingRowCard(icon: "trash.fill", title: "Delete account", rowBackground: rowBackground, rowStroke: rowStroke, isDestructive: true)
                }
                .buttonStyle(.plain)
                
                // Logout (destructive) -> custom dialog
                Button {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.95)) {
                        showingLogoutConfirmation = true
                    }
                } label: {
                    SettingRowCard(icon: "arrow.right.square.fill", title: "Logout", rowBackground: rowBackground, rowStroke: rowStroke, isDestructive: true)
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    // MARK: - Data Reset / Logout Actions
    
    /// Fully wipes all app data stored in UserDefaults and notifies the app to reload.
    private func performFullDataWipe() {
        logger.info("🗑️ Performing FULL data wipe (delete account)")
        doDataCleanup(fullWipe: true)
    }
    
    /// Logs the user out by cleaning user-specific data and notifying the app to reset state.
    /// Since the app stores user data in UserDefaults, this clears the same data as a full wipe.
    private func performLogout() {
        logger.info("🚪 Performing logout - clearing user data from UserDefaults")
        doDataCleanup(fullWipe: false)
    }
    
    /// Centralized cleanup used by logout and delete account
    private func doDataCleanup(fullWipe: Bool) {
        // Invalidate caches first
        QuestionnaireManager.invalidateCache()
        
        // Clear questionnaire-related persisted data
        QuestionnaireManager().clearAllData()
        
        // Reset streaks
        StreakManager.shared.resetStreak()
        
        // Remove profile image
        ProfileImageManager.shared.removeProfileImage()
        
        // Cancel notifications
        NotificationManager.shared.cancelAllNotifications()
        
        // Remove the entire UserDefaults persistent domain
        if let bundleID = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleID)
            UserDefaults.standard.synchronize()
            logger.info("✅ Removed UserDefaults persistent domain for \(bundleID)")
        }
        
        // Reset in-memory AppState and drive navigation to Start screen
        withAnimation(.easeInOut) {
            appState.setAuthenticated(false)
            appState.hasCompletedOnboarding = false
            appState.currentOnboardingStep = .valueProposition
            appState.hasShownSignInPopupThisSession = false
            appState.hasUserPermanentlyDismissedSignIn = false
            appState.appLaunchCount = 0
            appState.shouldShowIntroAnimations = true
            appState.shouldTriggerIntroAnimations = true
            appState.isFirstDashboardViewAfterOnboarding = false
        }
        
        // Notify the app to reset in-memory state and recalculate
        NotificationCenter.default.post(name: NSNotification.Name("AppDataReset"), object: nil)
        
        // Optional: broadcast an explicit navigation intent if your ContentView listens for it
        NotificationCenter.default.post(name: NSNotification.Name("NavigateToStart"), object: nil)
        
        // Dismiss settings after operation so parent view can react to the state change
        dismiss()
    }
}

// MARK: - Custom Confirm Dialog

struct CustomDialogView: View {
    let emoji: String
    let message: String
    let primaryTitle: String
    let secondaryTitle: String
    let primaryIsDestructive: Bool
    let onPrimary: () -> Void
    let onCancel: () -> Void
    
    private let cornerRadius: CGFloat = 22
    
    var body: some View {
        ZStack {
            Color.black
                .opacity(0.7)
                .ignoresSafeArea()
            VStack(spacing: 18) {
                Image(emoji)
                    .frame(width: 60, height: 60)
                    .padding()
                
                Text(message)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 12)
                    .fixedSize(horizontal: false, vertical: true)
                
                // Primary action button
                Button(action: onPrimary) {
                    Text(primaryTitle)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(
                                colors: [Color(hex: "#18EF47"), Color(hex: "#0E8929")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(Capsule())
                        .shadow(color: Color.black.opacity(0.35), radius: 8, x: 0, y: 6)
                }
                .padding(.top, 4)
                
                // Cancel
                if !secondaryTitle.isEmpty {
                    Button(action: onCancel) {
                        Text(secondaryTitle)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                            .frame(maxWidth: .infinity)
                    }
                    .padding(.bottom, 6)
                }
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 22)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .stroke(Color.white.opacity(0.25), lineWidth: 1)
                    )
            )
            .padding(.horizontal, 28)
            .transition(.scale.combined(with: .opacity))
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
