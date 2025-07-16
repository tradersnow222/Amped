import SwiftUI

/// Bottom pricing section component - Rules: Extracted to keep files under 300 lines
struct BottomPricingSection: View {
    @ObservedObject var viewModel: PaymentViewModel
    @EnvironmentObject var themeManager: BatteryThemeManager
    @Binding var annualButtonPressed: Bool
    @Binding var monthlyButtonPressed: Bool
    var processPurchase: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {  // Increased from 12 for better spacing with legal links
            // Add extra space at the top for taller background
            Spacer()
                .frame(height: 25)
            // Single pricing option with cleaned up design
            VStack(spacing: 8) {  // Reduced from 12
                // Single Plan - Primary CTA
                Button(action: {
                    // Psychological reward: slight delay with animation
                    annualButtonPressed = true
                    // Enhanced haptic for premium feel
                    let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
                    impactFeedback.impactOccurred()
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        viewModel.selectedPlan = .annual // Using annual as the plan type
                        processPurchase()
                        annualButtonPressed = false
                    }
                }) {
                    ZStack {
                        VStack(spacing: 4) {
                            Text("Start 7-Day Free Trial")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text("Then $6.99/week")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .frame(height: 60)
                    .frame(maxWidth: .infinity)
                    .background(
                        LinearGradient(
                            colors: [Color.ampedGreen, Color.ampedGreen.opacity(0.9)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(12)
                    .shadow(color: Color.ampedGreen.opacity(0.2), radius: 4, y: 2)
                    .scaleEffect(annualButtonPressed ? 0.97 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: annualButtonPressed)
                }
                .disabled(viewModel.isProcessing)
            }
            .padding(.horizontal, 24)
            
            // Simplified footer
            Text("Limited-time pricing. Cancel anytime.")
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(.secondary.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.top, 8)  // Increased padding for better spacing
            
            // Legal links
            HStack(spacing: 16) {
                Button("Privacy Policy") {
                    // Open privacy policy
                }
                .font(.system(size: 12))
                .foregroundColor(.secondary.opacity(0.6))
                
                Text("•")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary.opacity(0.4))
                
                Button("Terms of Use") {
                    // Open terms
                }
                .font(.system(size: 12))
                .foregroundColor(.secondary.opacity(0.6))
            }
            .padding(.bottom, 20)  // Increased from 16 for better spacing
        }
        .background(
            Color.cardBackground
                .shadow(color: .black.opacity(0.05), radius: 8, y: -5)
        )
    }
} 