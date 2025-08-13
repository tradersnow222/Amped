import SwiftUI

/// Smart notification permission request view optimized for conversion
/// Placed after payment to maximize value understanding
struct NotificationPermissionView: View {
    let onContinue: () -> Void
    
    @State private var isRequesting = false
    @State private var showingBenefits = false
    @StateObject private var notificationManager = NotificationManager.shared
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Header with icon
            VStack(spacing: 24) {
                // Notification icon with subtle animation
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.1))
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: "bell.badge")
                        .font(.system(size: 32, weight: .medium))
                        .foregroundColor(.blue)
                        .scaleEffect(showingBenefits ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: showingBenefits)
                }
                
                // Main heading - clear and benefit-focused
                VStack(spacing: 12) {
                    Text("Stay On Track")
                        .font(.system(size: 28, weight: .bold, design: .default))
                        .foregroundColor(.primary)
                    
                    Text("Get gentle reminders to check your progress and celebrate wins")
                        .font(.system(size: 17, weight: .regular))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                }
            }
            .padding(.horizontal, 40)
            
            Spacer()
            
            // Benefits section
            VStack(spacing: 20) {
                benefitRow(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Daily Progress",
                    description: "See how today's choices impact your health"
                )
                
                benefitRow(
                    icon: "flame",
                    title: "Streak Reminders",
                    description: "Keep your healthy habits going strong"
                )
                
                benefitRow(
                    icon: "trophy",
                    title: "Celebrate Wins",
                    description: "Get recognized for milestones and achievements"
                )
            }
            .padding(.horizontal, 32)
            
            Spacer()
            
            // Action buttons
            VStack(spacing: 16) {
                // Primary action - allow notifications
                Button(action: {
                    handleAllowNotifications()
                }) {
                    HStack {
                        if isRequesting {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Text("Enable Reminders")
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(isRequesting)
                
                // Secondary action - skip (but make it less prominent)
                Button(action: {
                    onContinue()
                }) {
                    Text("Maybe Later")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 8)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 40)
        }
        .background(Color(.systemBackground))
        .onAppear {
            // Subtle animation on appear
            withAnimation(.easeInOut(duration: 2.0)) {
                showingBenefits = true
            }
        }
    }
    
    @ViewBuilder
    private func benefitRow(icon: String, title: String, description: String) -> some View {
        HStack(spacing: 16) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(.blue)
                .frame(width: 24, height: 24)
            
            // Text content
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
    
    private func handleAllowNotifications() {
        isRequesting = true
        
        Task {
            let granted = await notificationManager.requestPermissions()
            
            await MainActor.run {
                isRequesting = false
                
                // Always continue regardless of permission result
                // This prevents friction in the onboarding flow
                onContinue()
                
                // Set up observers if granted
                if granted {
                    notificationManager.setupStreakObservers()
                }
            }
        }
    }
}

// MARK: - Preview

struct NotificationPermissionView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            NotificationPermissionView(onContinue: {})
                .previewDisplayName("Light Mode")
            
            NotificationPermissionView(onContinue: {})
                .preferredColorScheme(.dark)
                .previewDisplayName("Dark Mode")
        }
    }
}
