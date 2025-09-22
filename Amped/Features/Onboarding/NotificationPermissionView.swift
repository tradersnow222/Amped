import SwiftUI

/// Smart notification permission request view optimized for conversion
/// Placed after payment to maximize value understanding
struct NotificationPermissionView: View {
    let onContinue: () -> Void
    let onBackTap: (() -> Void)?
    
    @State private var isRequesting = false
    @State private var showingBenefits = false
    @StateObject private var notificationManager = NotificationManager.shared
    
    var body: some View {
        VStack(spacing: 0) {
            // Back arrow button - always visible
            HStack {
                Button(action: {
                    onBackTap?()
                }) {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 24, height: 24)
                        .padding(8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(red: 0.15, green: 0.15, blue: 0.15, opacity: 1.0)) // #272727
                        )
                }
                .disabled(onBackTap == nil)
                
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            
            Spacer()
            
            // Header with bell icon
            VStack(spacing: 24) {
                // Large bell icon with gradient background
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color("ampedGreen"), Color("ampedYellow")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80, height: 80)
                    
                    Image("notifications_active")
                        .resizable()
                        .frame(width: 36, height: 36)
                }
                
                // Title and description
                VStack(spacing: 12) {
                    Text("Stay on Track!")
                        .font(.system(size: 32, weight: .bold, design: .default))
                        .foregroundColor(.white)
                    
                    Text("Get personalised reminders based on your lifespan goals")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
            }
            .padding(.horizontal, 24)
            
            Spacer()
                .frame(height:28)
            
            // Notification preview card
            VStack(spacing: 16) {
                // Notification card stack
                ZStack(alignment: .topLeading) {
                    // Background card 1 (furthest back) - extends beyond main card
                    Rectangle()
                        .fill(Color.gray.opacity(0.5))
                        .frame(width:310, height: 80)
                        .cornerRadius(12)
                        .offset(x: 18, y: 60)
                    
                    // Background card 2 (middle) - extends beyond main card
                    Rectangle()
                        .fill(Color.gray.opacity(0.9))
                        .frame(width:330, height: 80)
                        .cornerRadius(12)
                        .offset(x: 9, y: 52)
                    
                    // Main notification card (front)
                    VStack(spacing: 12) {
                        HStack {
                            HStack(spacing: 8) {
                                Image(systemName: "bell")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.gray)
                                Text("AMPED")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.black.opacity(0.8))
                            }
                            Spacer()
                            Text("1h ago")
                                .font(.system(size: 12, weight: .regular))
                                .foregroundColor(.gray)
                        }
                        
                        Text("Congratulations! You just added 30 minutes to your lifespan")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(.black.opacity(0.8))
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Text("3 more notifications")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(.gray.opacity(0.7))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(16)
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                }
                .padding(.horizontal, 24)
                
                Spacer()
                    .frame(height: 16)
                
                // Benefits section
                VStack(spacing: 8) {
                    benefitRow(
                        icon: "goal",
                        title: "Stay on track with your daily time targets"
                    )
                    
                    benefitRow(
                        icon: "progress",
                        title: "Quick updates on your lifespan gains"
                    )
                    
                    benefitRow(
                        icon: "verified",
                        title: "Celebrate your achievements!"
                    )
                }
                .padding(.leading, 24)
            }
            
            Spacer()
            
            // Action buttons
            VStack(spacing: 16) {
                // Enable Reminders button
                Button(action: {
                    handleAllowNotifications()
                }) {
                    Text("Enable Reminders")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 25)
                                .stroke(
                                    LinearGradient(
                                        colors: [Color("ampedGreen"), Color("ampedYellow")],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    ),
                                    lineWidth: 2
                                )
                                .background(
                                    RoundedRectangle(cornerRadius: 25)
                                        .fill(Color.black)
                                )
                        )
                }
                .disabled(isRequesting)
                
                // Maybe Later link
                Button(action: {
                    onContinue()
                }) {
                    Text("Maybe Later")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.white)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .background(Color.black)
        .onAppear {
            withAnimation(.easeInOut(duration: 2.0)) {
                showingBenefits = true
            }
        }
    }
    
    @ViewBuilder
    private func benefitRow(icon: String, title: String) -> some View {
        HStack(spacing: 12) {
            // Custom icon (already has circle)
            Image(icon)
                .resizable()
                .frame(width: 19, height: 19)
            
            // Text content
            Text(title)
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(.white)
                .multilineTextAlignment(.leading)
            
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
            NotificationPermissionView(onContinue: {}, onBackTap: {})
                .previewDisplayName("Light Mode")
            
            NotificationPermissionView(onContinue: {}, onBackTap: {})
                .preferredColorScheme(.dark)
                .previewDisplayName("Dark Mode")
        }
    }
}
