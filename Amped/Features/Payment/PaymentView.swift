import SwiftUI
import StoreKit

/// Clean, sleek payment screen for NEW subscriptions only (following Apple best practices)
struct PaymentView: View {
    // MARK: - Properties
    
    @StateObject private var viewModel = PaymentViewModel()
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var themeManager: BatteryThemeManager
    @Environment(\.presentationMode) private var presentationMode
    
    // Callback to proceed to next step
    var onContinue: (() -> Void)?
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Clean header with minimal close button
                headerView
                
                // Main content in scrollable area
                ScrollView {
                    VStack(spacing: 32) {
                        // Hero section with battery animation
                        heroSectionView
                        
                        // Clean subscription options
                        subscriptionSectionView
                        
                        // Simple benefits
                        benefitsSectionView
                        
                        // Legal/trial info only
                        legalSectionView
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                }
                
                // Bottom CTA and progress
                bottomSectionView
            }
            
            // Processing overlay
            if viewModel.isProcessing {
                ProcessingOverlay()
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
        }
        .withDeepBackground()
    }
    
    // MARK: - View Components
    
    private var headerView: some View {
        HStack {
            Spacer()
            
            // Minimal close button
            Button(action: {
                // Simple skip option - continue with free version
                viewModel.skipPayment {
                    onContinue?()
                }
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.secondary)
                    .padding(12)
                    .background(Color.gray.opacity(0.1))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }
    
    private var heroSectionView: some View {
        VStack(spacing: 20) {
            // Battery charging animation
            BatteryChargingAnimation()
                .frame(width: 80, height: 40)
            
            // Simple, powerful headline
            Text("Unlock Full Power")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(themeManager.textColor)
                .multilineTextAlignment(.center)
            
            // Benefit-focused subtitle
            Text("Get deeper insights and maximize your health potential")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
        }
    }
    
    private var subscriptionSectionView: some View {
        VStack(spacing: 16) {
            if viewModel.areProductsLoaded {
                // Clean subscription options
                subscriptionOptionsView
            } else if viewModel.isProcessing {
                // Simple loading state
                loadingStateView
            } else {
                // Graceful fallback with retry
                fallbackOptionsView
            }
        }
    }
    
    private var subscriptionOptionsView: some View {
        VStack(spacing: 12) {
            // Annual option (highlighted as best value)
            if let annualProduct = viewModel.annualProduct {
                SubscriptionOptionCard(
                    title: "Annual",
                    price: annualProduct.formattedPrice,
                    period: "year",
                    monthlyEquivalent: calculateMonthlyEquivalent(for: annualProduct),
                    discount: "Save 58%",
                    isSelected: viewModel.selectedPlan == .annual,
                    isBestValue: true
                ) {
                    viewModel.selectedPlan = .annual
                }
            }
            
            // Monthly option
            if let monthlyProduct = viewModel.monthlyProduct {
                SubscriptionOptionCard(
                    title: "Monthly",
                    price: monthlyProduct.formattedPrice,
                    period: "month",
                    isSelected: viewModel.selectedPlan == .monthly
                ) {
                    viewModel.selectedPlan = .monthly
                }
            }
        }
    }
    
    private var loadingStateView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .ampedGreen))
                .scaleEffect(1.2)
            
            Text("Loading options...")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.secondary)
        }
        .frame(height: 140)
    }
    
    private var fallbackOptionsView: some View {
        VStack(spacing: 16) {
            // Show fallback options with predefined pricing
            SubscriptionOptionCard(
                title: "Annual",
                price: "$39.99",
                period: "year",
                monthlyEquivalent: "$3.33/month",
                discount: "Save 58%",
                isSelected: viewModel.selectedPlan == .annual,
                isBestValue: true
            ) {
                viewModel.selectedPlan = .annual
            }
            
            SubscriptionOptionCard(
                title: "Monthly",
                price: "$9.99",
                period: "month",
                isSelected: viewModel.selectedPlan == .monthly
            ) {
                viewModel.selectedPlan = .monthly
            }
            
            // Subtle retry option
            Button("Refresh pricing") {
                viewModel.loadProducts()
            }
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(.ampedGreen)
            .padding(.top, 8)
        }
    }
    
    private var benefitsSectionView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("What you'll get:")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(themeManager.textColor)
            
            // Streamlined benefits
            CleanBenefitRow(icon: "chart.line.uptrend.xyaxis", text: "Advanced health analytics")
            CleanBenefitRow(icon: "heart.text.square", text: "Detailed heart insights")
            CleanBenefitRow(icon: "clock.arrow.2.circlepath", text: "Historical data access")
            CleanBenefitRow(icon: "bell.badge", text: "Smart notifications")
        }
        .padding(.horizontal, 4)
    }
    
    private var legalSectionView: some View {
        VStack(spacing: 12) {
            Text("7-day free trial • Cancel anytime")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.secondary)
        }
    }
    
    private var bottomSectionView: some View {
        VStack(spacing: 16) {
            // Primary CTA button
            Button(action: {
                processPurchase()
            }) {
                HStack {
                    if viewModel.isProcessing {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    }
                    
                    Text(viewModel.isProcessing ? "Processing..." : "Start Free Trial")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    LinearGradient(
                        colors: [Color.ampedGreen, Color.ampedGreen.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(16)
                .shadow(color: Color.ampedGreen.opacity(0.3), radius: 8, y: 4)
            }
            .disabled(viewModel.isProcessing)
            .padding(.horizontal, 24)
            .hapticFeedback(.heavy)
            
            // Progress indicator
            ProgressIndicator(currentStep: 6, totalSteps: 6)
                .padding(.bottom, 20)
        }
        .background(
            Color.cardBackground
                .shadow(color: .black.opacity(0.1), radius: 10, y: -5)
        )
    }
    
    // MARK: - Helper Methods
    
    private func processPurchase() {
        viewModel.processPurchase {
            onContinue?()
        }
    }
    
    private func calculateMonthlyEquivalent(for product: Product) -> String? {
        guard product.isAnnual else { return nil }
        
        let monthlyPrice = product.price / 12
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = product.priceFormatStyle.locale
        
        if let formattedPrice = formatter.string(from: NSDecimalNumber(decimal: monthlyPrice)) {
            return "\(formattedPrice)/month"
        }
        
        return nil
    }
}

// MARK: - Supporting Views

struct BatteryChargingAnimation: View {
    @State private var isCharging = false
    
    var body: some View {
        ZStack {
            // Battery outline
            RoundedRectangle(cornerRadius: 4)
                .stroke(Color.ampedGreen, lineWidth: 2)
                .frame(width: 60, height: 32)
            
            // Battery fill with animation
            HStack(spacing: 2) {
                ForEach(0..<4) { index in
                    RoundedRectangle(cornerRadius: 1)
                        .fill(Color.ampedGreen)
                        .frame(width: 10, height: 20)
                        .opacity(isCharging ? 1.0 : (index < 2 ? 1.0 : 0.3))
                        .animation(
                            Animation.easeInOut(duration: 0.6)
                                .repeatForever()
                                .delay(Double(index) * 0.15),
                            value: isCharging
                        )
                }
            }
            
            // Battery tip
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.ampedGreen)
                .frame(width: 4, height: 16)
                .offset(x: 35)
        }
        .onAppear {
            isCharging = true
        }
    }
}

struct SubscriptionOptionCard: View {
    let title: String
    let price: String
    let period: String
    let monthlyEquivalent: String?
    let discount: String?
    let isSelected: Bool
    let isBestValue: Bool
    let action: () -> Void
    
    init(
        title: String,
        price: String,
        period: String,
        monthlyEquivalent: String? = nil,
        discount: String? = nil,
        isSelected: Bool,
        isBestValue: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.price = price
        self.period = period
        self.monthlyEquivalent = monthlyEquivalent
        self.discount = discount
        self.isSelected = isSelected
        self.isBestValue = isBestValue
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(title)
                            .font(.system(size: 18, weight: .semibold))
                        
                        if let discount = discount {
                            Text(discount)
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.ampedGreen)
                                .cornerRadius(8)
                        }
                    }
                    
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(price)
                            .font(.system(size: 22, weight: .bold))
                        
                        Text("/ \(period)")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    
                    if let monthlyEquivalent = monthlyEquivalent {
                        Text(monthlyEquivalent)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.ampedGreen)
                    }
                }
                
                Spacer()
                
                // Selection indicator
                Circle()
                    .stroke(isSelected ? Color.ampedGreen : Color.gray.opacity(0.4), lineWidth: 2)
                    .frame(width: 24, height: 24)
                    .overlay(
                        Circle()
                            .fill(Color.ampedGreen)
                            .frame(width: 12, height: 12)
                            .opacity(isSelected ? 1 : 0)
                    )
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                isSelected ? Color.ampedGreen : Color.gray.opacity(0.2),
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
            )
            .overlay(
                // Best value badge
                Group {
                    if isBestValue {
                        Text("BEST VALUE")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(Color.ampedGreen)
                            .cornerRadius(8)
                            .offset(y: -16)
                    }
                },
                alignment: .top
            )
        }
        .foregroundColor(.primary)
        .hapticFeedback(.selection)
    }
}

struct CleanBenefitRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.ampedGreen)
                .frame(width: 24, height: 24)
            
            Text(text)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.primary)
            
            Spacer()
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

// MARK: - Preview

struct PaymentView_Previews: PreviewProvider {
    static var previews: some View {
        PaymentView(onContinue: {})
            .environmentObject(AppState())
            .environmentObject(BatteryThemeManager())
    }
} 