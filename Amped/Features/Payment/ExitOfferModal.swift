import SwiftUI

/// Exit offer modal component for payment screen - Rules: Extracted to keep files under 300 lines
struct ExitOfferModal: View {
    let onClaim: () -> Void
    let onDecline: () -> Void
    @EnvironmentObject var themeManager: BatteryThemeManager
    @State private var animateContent = false
    
    var body: some View {
        ZStack {
            // Background overlay
            Color.black.opacity(0.4)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    // Prevent dismissing by tapping outside
                }
            
            // Modal content
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    Text("Wait — enjoy 50% off your first year!")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(themeManager.textColor)
                        .multilineTextAlignment(.center)
                    
                    Text("Stick with it and save. Get full access now for just $19.99/year.")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
                .opacity(animateContent ? 1 : 0)
                .offset(y: animateContent ? 0 : 10)
                .animation(.easeOut(duration: 0.4).delay(0.1), value: animateContent)
                
                // Buttons
                VStack(spacing: 12) {
                    // Primary CTA
                    Button(action: onClaim) {
                        Text("Claim 50% Off – Start Free Trial")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(
                                LinearGradient(
                                    colors: [Color.ampedGreen, Color.ampedGreen.opacity(0.85)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(14)
                            .shadow(color: Color.ampedGreen.opacity(0.3), radius: 8, y: 3)
                    }
                    .hapticFeedback(.heavy)
                    
                    // Secondary link
                    Button(action: onDecline) {
                        Text("No thanks, I'll pay full price later")
                            .font(.system(size: 15, weight: .regular))
                            .foregroundColor(.secondary)
                            .frame(height: 44)
                    }
                    .hapticFeedback(.heavy)
                }
                .opacity(animateContent ? 1 : 0)
                .offset(y: animateContent ? 0 : 10)
                .animation(.easeOut(duration: 0.4).delay(0.2), value: animateContent)
            }
            .padding(28)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.cardBackground)
                    .shadow(color: Color.black.opacity(0.2), radius: 20, y: 8)
            )
            .padding(.horizontal, 32)
            .scaleEffect(animateContent ? 1 : 0.95)
            .animation(.spring(response: 0.3), value: animateContent)
        }
        .onAppear {
            withAnimation {
                animateContent = true
            }
        }
    }
}

// MARK: - Preview

struct ExitOfferModal_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.gray
            
            ExitOfferModal(
                onClaim: { print("Claimed offer") },
                onDecline: { print("Declined offer") }
            )
            .environmentObject(BatteryThemeManager())
        }
    }
} 