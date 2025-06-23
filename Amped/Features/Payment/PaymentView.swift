import SwiftUI
import StoreKit

/// Clean, focused payment screen with conversion psychology
struct PaymentView: View {
    // MARK: - Properties
    
    @StateObject private var viewModel = PaymentViewModel()
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var themeManager: BatteryThemeManager
    @Environment(\.presentationMode) private var presentationMode
    @State private var showExitOffer = false
    @State private var animateBattery = false
    @State private var annualButtonPressed = false
    @State private var monthlyButtonPressed = false
    @State private var showBenefits = false  // New state for benefits animation
    @State private var showPricingSection = false  // New state for pricing section animation
    @State private var showExitButton = false  // New state for exit button visibility
    @State private var showTestimonial = false  // New state for testimonial visibility
    
    // Callback to proceed to next step
    var onContinue: (() -> Void)?
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // Background tap area
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    // Show exit button when tapping on background
                    if !showExitButton {
                        withAnimation(.easeOut(duration: 0.5)) {
                            showExitButton = true
                        }
                    }
                }
            
            VStack(spacing: 0) {
                // Clean header with X button
                headerView
                
                // Main content without scroll
                VStack(spacing: 16) {  // Reduced from 20
                    // Personal headline
                    personalHeadlineView
                    
                    // Simple battery visual
                    scientificBatteryView
                        .opacity(animateBattery ? 1.0 : 0.0)
                        .scaleEffect(animateBattery ? 1.0 : 0.75)
                        .animation(.easeOut(duration: 1.0).delay(0.3), value: animateBattery)
                    
                    Spacer(minLength: 20)  // Space between battery and testimonial
                    
                    // Social proof - moved to center between battery and benefits
                    socialProofView
                        .opacity(showTestimonial ? 1.0 : 0.0)
                        .scaleEffect(showTestimonial ? 1.0 : 0.85)
                        .animation(.easeInOut(duration: 1.5), value: showTestimonial)
                    
                    Spacer(minLength: 20)  // Space between testimonial and benefits
                    
                    // Zero-friction benefits
                    benefitsListView
                    
                    Spacer(minLength: 20)  // Reduced minimum space
                }
                .padding(.horizontal, 24)
                .padding(.top, 8)
                
                // Bottom pricing section with two options
                bottomPricingSection
                    .opacity(showPricingSection ? 1.0 : 0.0)
                    .offset(y: showPricingSection ? 0 : 60)
                    .animation(.easeOut(duration: 1.0), value: showPricingSection)
                    .onTapGesture { } // Consume taps on pricing section to prevent background tap
            }
            .blur(radius: showExitOffer ? 8 : 0)
            .animation(.easeInOut(duration: 0.25), value: showExitOffer)
            
            // Processing overlay
            if viewModel.isProcessing {
                ProcessingOverlay()
            }
            
            // Exit offer modal
            if showExitOffer {
                ExitOfferModal(
                    onClaim: {
                        withAnimation(.spring(response: 0.3)) {
                            showExitOffer = false
                        }
                        viewModel.selectedPlan = .annual
                        processPurchase()
                    },
                    onDecline: {
                        withAnimation(.spring(response: 0.3)) {
                            showExitOffer = false
                        }
                        viewModel.skipPayment {
                            onContinue?()
                        }
                    }
                )
                .transition(.scale.combined(with: .opacity))
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
            
            // Start with headline and battery together
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                animateBattery = true
            }
            
            // Show testimonial after headline/battery complete (1.6s total)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
                withAnimation(.easeInOut(duration: 1.2)) {
                    showTestimonial = true
                }
            }
            
            // Show benefits after testimonial (2.8s total)
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.8) {
                withAnimation(.easeOut(duration: 1.0)) {
                    showBenefits = true
                }
            }
            
            // Show pricing section last (4.0s total)
            DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                withAnimation(.easeOut(duration: 1.0)) {
                    showPricingSection = true
                }
            }
        }
        .withDeepBackground()
    }
    
    // MARK: - View Components
    
    private var headerView: some View {
        HStack {
            // Exit button (X) - only shown when showExitButton is true
            if showExitButton {
                Button(action: {
                    withAnimation(.spring(response: 0.3)) {
                        showExitOffer = true
                    }
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                        .padding(12)
                        .background(Color.gray.opacity(0.1))
                        .clipShape(Circle())
                }
                .hapticFeedback(.heavy)
                .transition(.scale.combined(with: .opacity))
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .frame(height: 44) // Fixed height to prevent layout shift
    }
    
    private var personalHeadlineView: some View {
        Text("Better habits. Longer life.")
            .font(.system(size: 32, weight: .bold, design: .default))
            .foregroundColor(themeManager.textColor)
            .multilineTextAlignment(.center)
            .scaleEffect(animateBattery ? 1.0 : 0.93)
            .opacity(animateBattery ? 1.0 : 0.0)
            .animation(.easeOut(duration: 1.0).delay(0.3), value: animateBattery)
    }
    
    private var scientificBatteryView: some View {
        ZStack {
            // Battery outline with scientific elements
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.ampedGreen, lineWidth: 3)
                .frame(width: 120, height: 60)
                .overlay(
                    HStack(spacing: 0) {
                        // DNA helix symbol
                        Image(systemName: "waveform.path.ecg")
                            .font(.system(size: 24))
                            .foregroundColor(.ampedGreen)
                        
                        // Plus sign
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white.opacity(0.7))
                            .padding(.horizontal, 8)
                        
                        // AI brain symbol
                        Image(systemName: "brain")
                            .font(.system(size: 24))
                            .foregroundColor(.ampedGreen)
                    }
                )
            
            // Battery tip
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.ampedGreen)
                .frame(width: 6, height: 30)
                .offset(x: 68)
        }
    }
    
    private var socialProofView: some View {
        VStack(spacing: 8) {
            Text("\"The Health App That\nWill Change Your Life\"")
                .font(.system(size: 28, weight: .semibold, design: .serif))  // Increased from 22 to 28
                .foregroundColor(themeManager.textColor)
                .multilineTextAlignment(.center)
                .italic()
                .fixedSize(horizontal: false, vertical: true)  // Prevent text cutoff
                .padding(.horizontal, 10)  // Add padding to prevent edge cutoff
            
            Text("— FEATURED IN APP STORE")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
                .tracking(1.2)
        }
        .padding(.vertical, 8)  // Add some vertical padding
    }
    
    private var benefitsListView: some View {
        BenefitsListView(showBenefits: $showBenefits)
    }
    
    private var bottomPricingSection: some View {
        BottomPricingSection(
            viewModel: viewModel,
            annualButtonPressed: $annualButtonPressed,
            monthlyButtonPressed: $monthlyButtonPressed,
            processPurchase: processPurchase
        )
    }
    
    // MARK: - Helper Methods
    
    private func processPurchase() {
        viewModel.processPurchase {
            onContinue?()
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