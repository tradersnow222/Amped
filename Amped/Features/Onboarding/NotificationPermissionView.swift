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
                // Notification icon with sophisticated glass morphism styling
                ZStack {
                    // Outer glow ring
                    Circle()
                        .stroke(
                            Color.ampedGreen.opacity(showingBenefits ? 0.4 : 0.2),
                            lineWidth: 2
                        )
                        .frame(width: 90, height: 90)
                        .blur(radius: showingBenefits ? 3 : 1)
                        .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: showingBenefits)
                    
                    // Glass morphism background
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 80, height: 80)
                        .overlay(
                            Circle()
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(0.3),
                                            Color.ampedGreen.opacity(0.4),
                                            Color.white.opacity(0.1)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1.5
                                )
                        )
                        .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
                        .shadow(color: Color.ampedGreen.opacity(0.2), radius: 15, x: 0, y: 3)
                    
                    Image(systemName: "bell.badge")
                        .font(.system(size: 32, weight: .medium))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color.ampedGreen,
                                    Color.ampedGreen.opacity(0.8)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .scaleEffect(showingBenefits ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: showingBenefits)
                }
                
                // Main heading with sophisticated typography
                VStack(spacing: 12) {
                    Text("Stay On Track")
                        .font(.system(size: 32, weight: .bold, design: .default))
                        .tracking(0.5)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color.white,
                                    Color.white.opacity(0.9)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                    
                    Text("Get personalized reminders based on your daily goals")
                        .font(.system(size: 17, weight: .regular))
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                }
            }
            .padding(.horizontal, 40)
            
            Spacer()
            
            // Benefits section
            VStack(spacing: 20) {
                benefitRow(
                    icon: "target",
                    title: "Goal Reminders",
                    description: "Stay on track with your daily time targets"
                )
                
                benefitRow(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Progress Check-ins",
                    description: "Quick updates on your health gains"
                )
                
                benefitRow(
                    icon: "trophy",
                    title: "Celebrate Wins",
                    description: "Get recognized when you hit your goals"
                )
            }
            .padding(.horizontal, 32)
            
            Spacer()
            
            // Action buttons with glass morphism styling
            VStack(spacing: 16) {
                // Primary action - allow notifications with sophisticated theming
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
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.white)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        ZStack {
                            // Base gradient background
                            LinearGradient(
                                colors: [
                                    Color.ampedGreen.opacity(0.9),
                                    Color.ampedGreen,
                                    Color.ampedGreen.opacity(0.8)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            
                            // Glass overlay
                            RoundedRectangle(cornerRadius: 16)
                                .fill(.ultraThinMaterial.opacity(0.3))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(
                                            LinearGradient(
                                                colors: [
                                                    Color.white.opacity(0.4),
                                                    Color.white.opacity(0.1)
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 1.5
                                        )
                                )
                        }
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: Color.ampedGreen.opacity(0.4), radius: 15, x: 0, y: 8)
                    .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .disabled(isRequesting)
                .scaleEffect(isRequesting ? 0.98 : 1.0)
                .animation(.easeInOut(duration: 0.2), value: isRequesting)
                
                // Secondary action - skip with subtle glass styling
                Button(action: {
                    onContinue()
                }) {
                    Text("Maybe Later")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                        .padding(.vertical, 12)
                        .padding(.horizontal, 24)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.ultraThinMaterial.opacity(0.2))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                )
                        )
                }
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 40)
        }
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
            // Icon with glass morphism styling
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial.opacity(0.3))
                    .frame(width: 32, height: 32)
                    .overlay(
                        Circle()
                            .stroke(
                                Color.white.opacity(0.2),
                                lineWidth: 1
                            )
                    )
                
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.ampedGreen)
            }
            
            // Text content with themed colors
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.white.opacity(0.7))
                    .lineLimit(2)
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
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
