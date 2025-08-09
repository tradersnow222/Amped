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
                    .frame(height: 42)
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
            
            // Legal links (open hosted URLs if available; fallback to in-app views)
            LegalLinksInlineView()
            .padding(.bottom, 20)  // Increased from 16 for better spacing
        }
        .background(
            Color.cardBackground
                .shadow(color: .black.opacity(0.05), radius: 8, y: -5)
        )
    }
} 

// MARK: - Legal Links Inline Component

private struct LegalLinksInlineView: View {
    // Placeholder URLs: replace with hosted links when available
    private let privacyURLString: String? = nil
    private let termsURLString: String? = nil
    @State private var showPrivacy = false
    @State private var showTerms = false
    
    var body: some View {
        HStack(spacing: 16) {
            Button("Privacy Policy") {
                if let urlString = privacyURLString, let url = URL(string: urlString) {
                    UIApplication.shared.open(url)
                } else {
                    showPrivacy = true
                }
            }
            .font(.system(size: 12))
            .foregroundColor(.secondary.opacity(0.6))
            .sheet(isPresented: $showPrivacy) {
                NavigationStack { PrivacyPolicyView() }
            }
            
            Text("•")
                .font(.system(size: 12))
                .foregroundColor(.secondary.opacity(0.4))
            
            Button("Terms of Use") {
                if let urlString = termsURLString, let url = URL(string: urlString) {
                    UIApplication.shared.open(url)
                } else {
                    showTerms = true
                }
            }
            .font(.system(size: 12))
            .foregroundColor(.secondary.opacity(0.6))
            .sheet(isPresented: $showTerms) {
                NavigationStack { TermsOfServiceView() }
            }
        }
    }
}