import SwiftUI
import StoreKit

/// Clean, sleek payment screen for NEW subscriptions only (following Apple best practices)
struct PaymentView: View {
    // MARK: - Properties
    
    @StateObject private var viewModel = PaymentViewModel()
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var themeManager: BatteryThemeManager
    @Environment(\.presentationMode) private var presentationMode
    @State private var showDiscountOffer = false
    @State private var animateBattery = false
    @State private var buttonPulsing = false // Track button pulse animation state
    
    // Animation constants
    private let pulseAnimationDuration: Double = 1.0
    
    // Callback to proceed to next step
    var onContinue: (() -> Void)?
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Clean header with restore button
                headerView
                
                // Main content without scroll
                VStack(spacing: 20) {
                    // Personal headline
                    personalHeadlineView
                    
                    // Visual demonstration with battery
                    visualDemonstrationView
                    
                    // Social proof
                    socialProofView
                    
                    Spacer()
                    
                    // Zero-friction benefits
                    benefitsListView
                    
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 8)
                
                // Bottom CTA section
                if !showDiscountOffer {
                    bottomCTASection
                }
            }
            .blur(radius: showDiscountOffer ? 6 : 0)
            .brightness(showDiscountOffer ? 0.1 : 0)
            
            // Processing overlay
            if viewModel.isProcessing {
                ProcessingOverlay()
            }
            
            // Discount offer overlay
            if showDiscountOffer {
                DiscountOfferView(
                    onAccept: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showDiscountOffer = false
                        }
                        viewModel.selectedPlan = .annual
                        processPurchase()
                    },
                    onDecline: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showDiscountOffer = false
                        }
                        viewModel.skipPayment {
                            onContinue?()
                        }
                    }
                )
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.95).combined(with: .opacity),
                    removal: .scale(scale: 0.95).combined(with: .opacity)
                ))
                .zIndex(1)
            }
        }
        .alert(isPresented: $viewModel.showError) {
            Alert(
                title: Text("Oops!"),
                message: Text(viewModel.errorMessage),
                dismissButton: .default(Text("Got it"))
            )
        }
        .onAppear {
            viewModel.appState = appState
            animateBattery = true
            
            // Start button pulsing after a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                buttonPulsing = true
            }
        }
        .withDeepBackground()
        .animation(.easeInOut(duration: 0.2), value: showDiscountOffer)
    }
    
    // MARK: - View Components
    
    private var headerView: some View {
        HStack {
            // Skip button (X)
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showDiscountOffer = true
                }
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.secondary)
                    .padding(12)
                    .background(Color.gray.opacity(0.1))
                    .clipShape(Circle())
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }
    
    private var personalHeadlineView: some View {
        VStack(spacing: 4) {
            HStack(spacing: 6) {
                Text("Try Amped")
                    .font(.system(size: 32, weight: .medium, design: .default))
                    .foregroundColor(themeManager.textColor)
                
                Text("for free")
                    .font(.system(size: 32, weight: .bold, design: .default))
                    .foregroundColor(.ampedGreen)
                    .shadow(color: .ampedGreen.opacity(0.3), radius: 4, x: 0, y: 2)
                    .overlay(
                        // Subtle electric glow effect
                        Text("for free")
                            .font(.system(size: 32, weight: .bold, design: .default))
                            .foregroundColor(.ampedGreen.opacity(0.1))
                            .blur(radius: 8)
                    )
                    .scaleEffect(animateBattery ? 1.0 : 0.8)
                    .opacity(animateBattery ? 1.0 : 0.0)
                    .animation(.easeOut(duration: 0.8).delay(0.3), value: animateBattery)
            }
            .tracking(0.5) // Slightly spaced out for modern feel
        }
        .multilineTextAlignment(.center)
        .padding(.bottom, 24) // Ample space below headline
    }
    
    private var visualDemonstrationView: some View {
        VStack(spacing: 20) {
            // Moved description above batteries
            Text("See how your daily habits impact your life")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            // Battery visualization
            HStack(spacing: 20) {
                // Life Impact Battery
                VStack(spacing: 8) {
                    Text("Life Impact")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    SimpleBatteryView(
                        percentage: animateBattery ? 0.85 : 0.3
                    )
                    .frame(width: 60, height: 30)
                    .animation(.easeInOut(duration: 1.5).delay(0.5), value: animateBattery)
                    
                    Text("+2.4 hrs")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.ampedGreen)
                }
                
                Image(systemName: "arrow.right")
                    .font(.system(size: 20))
                    .foregroundColor(.ampedGreen.opacity(0.6))
                
                // Life Projection Battery
                VStack(spacing: 8) {
                    Text("Life Expectancy")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    SimpleBatteryView(
                        percentage: animateBattery ? 0.92 : 0.88
                    )
                    .frame(width: 60, height: 30)
                    .animation(.easeInOut(duration: 1.5).delay(0.8), value: animateBattery)
                    
                    Text("91.2 yrs")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.ampedGreen)
                }
            }
        }
        .padding(.vertical, 20)
    }
    
    private var socialProofView: some View {
        VStack(spacing: 8) {
            Text("\"The Health App That\nWill Change Your Life\"")
                .font(.system(size: 20, weight: .semibold, design: .serif))
                .foregroundColor(themeManager.textColor)
                .multilineTextAlignment(.center)
                .italic()
            
            Text("— FEATURED IN APP STORE")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
                .tracking(1.2)
        }
    }
    
    private var benefitsListView: some View {
        VStack(alignment: .center, spacing: 12) {
            BenefitRow(icon: "checkmark", text: "No Payment Due Now", isHighlighted: true)
                .frame(maxWidth: 300)
            BenefitRow(icon: "chart.line.uptrend.xyaxis", text: "Real-time health tracking")
                .frame(maxWidth: 300)
            BenefitRow(icon: "battery.100.bolt", text: "Personalized life insights")
                .frame(maxWidth: 300)
            BenefitRow(icon: "lock.shield", text: "100% private on-device")
                .frame(maxWidth: 300)
        }
        .frame(maxWidth: .infinity)
    }
    
    private var bottomCTASection: some View {
        VStack(spacing: 16) {
            // Background for button
            ZStack {
                // Dark background square
                RoundedRectangle(cornerRadius: 32)
                    .fill(Color.black.opacity(0.15))
                    .frame(height: 108)
                    .padding(.horizontal, 22)
                
                // Main CTA button
                Button(action: {
                    processPurchase()
                }) {
                    VStack(spacing: 4) {
                        Text("Try For $0.00")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.white)
                            .shadow(color: Color.black.opacity(0.3), radius: 1, x: 0, y: 1)
                        
                        Text("7-day free trial")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.95))
                            .shadow(color: Color.black.opacity(0.3), radius: 1, x: 0, y: 1)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 64)
                    .background(
                        LinearGradient(
                            colors: [Color.ampedGreen.opacity(0.9), Color.ampedGreen],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(32)
                    .shadow(color: Color.ampedGreen.opacity(0.3), radius: 12, y: 6)
                }
                .disabled(viewModel.isProcessing)
                .padding(.horizontal, 24)
                .scaleEffect(buttonPulsing ? 1.05 : 1.0) // Pulse animation
                .animation(.easeInOut(duration: pulseAnimationDuration).repeatForever(autoreverses: true), value: buttonPulsing)
                .hapticFeedback(.heavy)
            }
            
            // Pricing details with clear trial terms
            VStack(spacing: 4) {
                Text("Then $39.99/yr ($3.33/mo)")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(themeManager.textColor)
            }
            
            // Legal links
            HStack(spacing: 16) {
                Button("Privacy Policy") {
                    // Open privacy policy
                }
                .font(.system(size: 13))
                .foregroundColor(.secondary)
                
                Text("•")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary.opacity(0.5))
                
                Button("Terms of Use") {
                    // Open terms
                }
                .font(.system(size: 13))
                .foregroundColor(.secondary)
            }
            .padding(.bottom, 20)
        }
        .background(
            Color.cardBackground
                .shadow(color: .black.opacity(0.08), radius: 10, y: -5)
        )
    }
    
    // MARK: - Helper Methods
    
    private func processPurchase() {
        viewModel.processPurchase {
            onContinue?()
        }
    }
}

// MARK: - Supporting Views

struct SimpleBatteryView: View {
    let percentage: Double
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Battery outline
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Color.ampedGreen, lineWidth: 2)
                
                // Battery fill
                RoundedRectangle(cornerRadius: 3)
                    .fill(
                        LinearGradient(
                            colors: [Color.ampedGreen, Color.ampedGreen.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geometry.size.width * CGFloat(percentage) - 4)
                    .padding(2)
                
                // Battery tip
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.ampedGreen)
                    .frame(width: 4, height: geometry.size.height * 0.5)
                    .offset(x: geometry.size.width - 2)
            }
        }
    }
}

struct BenefitRow: View {
    let icon: String
    let text: String
    var isHighlighted: Bool = false
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(isHighlighted ? .ampedGreen : .secondary)
                .frame(width: 24, height: 24)
            
            Text(text)
                .font(.system(size: 16, weight: isHighlighted ? .semibold : .medium))
                .foregroundColor(isHighlighted ? .primary : .secondary)
        }
    }
}

struct ProcessingOverlay: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 16) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .ampedGreen))
                    .scaleEffect(1.3)
                
                Text("Processing your subscription...")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
            }
            .padding(32)
            .background(Color.cardBackground)
            .cornerRadius(16)
            .shadow(radius: 20)
        }
    }
}

// MARK: - Discount Offer View

struct DiscountOfferView: View {
    let onAccept: () -> Void
    let onDecline: () -> Void
    @EnvironmentObject var themeManager: BatteryThemeManager
    
    var body: some View {
        ZStack {
            // Dark background overlay
            Color.black.opacity(0.3)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20) {
                // Info card style container
                VStack(spacing: 24) {
                    // Icon and title
                    VStack(spacing: 16) {
                        Image(systemName: "gift.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.ampedGreen)
                        
                        Text("Wait! Special Offer")
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text("Get 50% off your first year")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    // Offer details
                    HStack {
                        Text("Annual Plan")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("$49.99")
                                .font(.system(size: 14))
                                .strikethrough()
                                .foregroundColor(.white.opacity(0.5))
                            Text("$24.99")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(.ampedGreen)
                        }
                    }
                    
                    Text("First year only • Then $49.99/year")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.6))
                }
                .padding(28)
                .background(Color.cardBackground)
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.3), radius: 20, y: 10)
                
                // Action buttons
                VStack(spacing: 12) {
                    Button(action: onAccept) {
                        Text("Claim 50% Off")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                LinearGradient(
                                    colors: [Color.ampedGreen.opacity(0.9), Color.ampedGreen],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(28)
                            .shadow(color: Color.ampedGreen.opacity(0.3), radius: 8, y: 4)
                    }
                    .hapticFeedback(.heavy)
                    
                    Button(action: onDecline) {
                        Text("No thanks, continue")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                    }
                }
            }
            .padding(.horizontal, 32)
        }
    }
}

// MARK: - Preview

struct PaymentView_Previews: PreviewProvider {
    static var previews: some View {
        PaymentView(onContinue: {})
            .environmentObject(AppState())
            .environmentObject(BatteryThemeManager())
    }
} 