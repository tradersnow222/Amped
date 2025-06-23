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
            // Pricing title
            Text("Choose Your Plan")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(themeManager.textColor)
                .padding(.top, 16)  // Increased from 12
            
            // Two pricing options with cleaned up design
            VStack(spacing: 8) {  // Reduced from 12
                // Annual Plan - PRIMARY
                ZStack(alignment: .topTrailing) {  // Changed alignment for better badge positioning
                    Button(action: {
                        // Psychological reward: slight delay with animation
                        annualButtonPressed = true
                        // Enhanced haptic for premium feel
                        let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
                        impactFeedback.impactOccurred()
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            viewModel.selectedPlan = .annual
                            processPurchase()
                            annualButtonPressed = false
                        }
                    }) {
                        ZStack {
                            VStack(spacing: 4) {
                                Text("Start 7-Day Free Trial")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.white)
                                
                                Text("Then $39.99/year")
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
                    
                    // Best Value Banner - repositioned to not block button
                    ZStack {
                        // Star background
                        Image(systemName: "star.fill")
                            .font(.system(size: 70))  // Slightly smaller
                            .foregroundColor(.orange)
                            .shadow(color: .black.opacity(0.25), radius: 3, y: 2)
                        
                        Text("BEST\nVALUE")
                            .font(.system(size: 9, weight: .heavy))  // Slightly smaller
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .lineSpacing(2)
                    }
                    .rotationEffect(.degrees(-15))
                    .offset(x: 25, y: -25)  // Better positioning
                    .allowsHitTesting(false) // Prevent star from blocking button taps
                }
                
                // Monthly Plan - SECONDARY
                Button(action: {
                    monthlyButtonPressed = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        viewModel.selectedPlan = .monthly
                        processPurchase()
                        monthlyButtonPressed = false
                    }
                }) {
                    Text("$9.99/month (after free trial)")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color.primary.opacity(0.7))
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.clear)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                        .scaleEffect(monthlyButtonPressed ? 0.98 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: monthlyButtonPressed)
                }
                .disabled(viewModel.isProcessing)
                .simultaneousGesture(
                    TapGesture()
                        .onEnded { _ in
                            let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
                            impactFeedback.impactOccurred()
                        }
                )
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