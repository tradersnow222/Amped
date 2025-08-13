import SwiftUI

/// Compact streak display component for the dashboard
/// Following "Rules: Keep Swift files under 300 lines" guideline
struct StreakDisplayView: View {
    let streak: BatteryStreak
    let onTap: (() -> Void)?
    
    @State private var animateStreak = false
    
    init(streak: BatteryStreak, onTap: (() -> Void)? = nil) {
        self.streak = streak
        self.onTap = onTap
    }
    
    var body: some View {
        Button(action: {
            onTap?()
        }) {
            HStack(spacing: 12) {
                // Streak icon with level indicator
                ZStack {
                    Circle()
                        .fill(streakColor.opacity(0.2))
                        .frame(width: 44, height: 44)
                    
                    Text(streak.streakLevel.emoji)
                        .font(.system(size: 20))
                        .scaleEffect(animateStreak ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: animateStreak)
                }
                
                // Streak info
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Text("\(streak.currentStreak)")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(streakColor)
                        
                        Text(streak.currentStreak == 1 ? "day" : "days")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    
                    Text(streak.streakLevel.displayName)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Status indicator
                statusIndicator
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.secondarySystemBackground))
            )
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0)) {
                animateStreak = true
            }
        }
    }
    
    @ViewBuilder
    private var statusIndicator: some View {
        if streak.hasEngagedToday {
            // Green checkmark for today's engagement
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.green)
        } else if streak.isAtRisk {
            // Warning for at-risk streak
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.orange)
        } else {
            // Chevron to indicate tappable
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Color(.tertiaryLabel))
        }
    }
    
    private var streakColor: Color {
        switch streak.streakLevel {
        case .starting:
            return .gray
        case .building:
            return .blue
        case .developing:
            return .green
        case .strong:
            return .orange
        case .committed:
            return .purple
        case .dedicated:
            return .pink
        case .legendary:
            return .yellow
        }
    }
}

/// Milestone celebration overlay
struct MilestoneCelebrationView: View {
    let milestone: StreakMilestone
    let onDismiss: () -> Void
    
    @State private var showContent = false
    @State private var animateEmojis = false
    
    var body: some View {
        ZStack {
            // Backdrop
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    dismissWithAnimation()
                }
            
            // Celebration content
            VStack(spacing: 24) {
                // Animated emojis
                HStack(spacing: 8) {
                    ForEach(0..<5, id: \.self) { index in
                        Text("🎉")
                            .font(.system(size: 30))
                            .scaleEffect(animateEmojis ? 1.2 : 0.8)
                            .animation(.easeInOut(duration: 0.6).delay(Double(index) * 0.1).repeatForever(autoreverses: true), value: animateEmojis)
                    }
                }
                
                // Milestone content
                VStack(spacing: 16) {
                    // Personalized achievement message - Rules: Strategic personalization for maximum impact
                    Text(PersonalizationUtils.contextualMessage(
                        firstName: PersonalizationUtils.userFirstName,
                        context: .achievement(milestone.title)
                    ))
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                    
                    Text(milestone.message)
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                    
                    Text("Day \(milestone.day)")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.blue)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(20)
                }
                
                // Dismiss button
                Button(action: dismissWithAnimation) {
                    Text("Continue")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.blue)
                        .cornerRadius(12)
                }
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.systemBackground))
                    .shadow(radius: 20)
            )
            .padding(.horizontal, 40)
            .scaleEffect(showContent ? 1.0 : 0.8)
            .opacity(showContent ? 1.0 : 0.0)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                showContent = true
            }
            
            withAnimation(.easeInOut(duration: 1.0)) {
                animateEmojis = true
            }
        }
    }
    
    private func dismissWithAnimation() {
        withAnimation(.easeInOut(duration: 0.3)) {
            showContent = false
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onDismiss()
        }
    }
}

// MARK: - Previews

struct StreakDisplayView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            VStack(spacing: 16) {
                StreakDisplayView(
                    streak: BatteryStreak(currentStreak: 0, hasEngagedToday: false)
                )
                
                StreakDisplayView(
                    streak: BatteryStreak(currentStreak: 5, hasEngagedToday: true)
                )
                
                StreakDisplayView(
                    streak: BatteryStreak(currentStreak: 21, hasEngagedToday: false)
                )
                
                StreakDisplayView(
                    streak: BatteryStreak(currentStreak: 100, hasEngagedToday: true)
                )
            }
            .padding()
            .previewDisplayName("Streak States")
            
            MilestoneCelebrationView(
                milestone: StreakMilestone.milestone(for: 7) ?? StreakMilestone.milestones[0],
                onDismiss: {}
            )
            .previewDisplayName("Milestone Celebration")
        }
    }
}
