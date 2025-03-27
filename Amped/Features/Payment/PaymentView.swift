import SwiftUI
import StoreKit

/// Payment screen with subscription options
struct PaymentView: View {
    // MARK: - Properties
    
    @StateObject private var viewModel = PaymentViewModel()
    @EnvironmentObject var appState: AppState
    @Environment(\.themeManager) private var themeManager
    @Environment(\.presentationMode) private var presentationMode
    
    // Callback to proceed to next step
    var onContinue: (() -> Void)?
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // Main content
            VStack(spacing: 20) {
                // Close button
                HStack {
                    Spacer()
                    Button(action: {
                        viewModel.showDiscountPopup = true
                    }) {
                        Image(systemName: "xmark")
                            .font(.title2)
                            .foregroundColor(.secondary)
                            .padding()
                    }
                }
                
                // Title
                Text("Unlock Full Power")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .foregroundColor(themeManager.textColor)
                
                // Description
                Text("Supercharge your health insights and maximize your battery potential")
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
                
                // Spacer to push content up
                Spacer()
                
                // Premium benefits
                VStack(alignment: .leading, spacing: 16) {
                    Text("Premium Benefits")
                        .font(.title3)
                        .fontWeight(.bold)
                        .padding(.top)
                    
                    PaymentComponents.BenefitRow(icon: "chart.bar.fill", text: "Advanced health metrics and analytics")
                    PaymentComponents.BenefitRow(icon: "waveform.path.ecg", text: "Detailed heart rate and HRV analysis")
                    PaymentComponents.BenefitRow(icon: "chart.line.uptrend.xyaxis", text: "Unlimited historical data access")
                    PaymentComponents.BenefitRow(icon: "bell.fill", text: "Custom alerts and battery notifications")
                    PaymentComponents.BenefitRow(icon: "bolt.fill", text: "Priority battery recharging tips")
                }
                .padding(.horizontal, 30)
                
                Spacer()
                
                // Subscription options
                VStack(spacing: 16) {
                    // Yearly plan (with discount)
                    PaymentComponents.SubscriptionOption(
                        title: "Yearly",
                        price: "$39.99",
                        discountedPrice: "$79.98",
                        period: "year",
                        discount: "50% Off",
                        isSelected: viewModel.selectedPlan == .annual,
                        isBestValue: true,
                        action: { viewModel.selectedPlan = .annual }
                    )
                    
                    // Monthly plan
                    PaymentComponents.SubscriptionOption(
                        title: "Monthly",
                        price: "$9.99",
                        period: "month",
                        isSelected: viewModel.selectedPlan == .monthly,
                        action: { viewModel.selectedPlan = .monthly }
                    )
                }
                .padding(.horizontal, 20)
                
                // Trial note
                Text("Includes 7-day free trial. Cancel anytime.")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .padding(.top, 8)
                
                // Continue button
                Button(action: {
                    processPurchase()
                }) {
                    Text("Subscribe")
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.ampedGreen)
                        .foregroundColor(.white)
                        .cornerRadius(14)
                }
                .padding(.horizontal, 30)
                .padding(.top, 10)
                .padding(.bottom, 40)
            }
            
            // Processing overlay
            if viewModel.isProcessing {
                PaymentComponents.ProcessingOverlay()
            }
            
            // Discount popup
            if viewModel.showDiscountPopup {
                PaymentComponents.DiscountPopup(viewModel: viewModel)
            }
        }
        .alert(isPresented: $viewModel.showError) {
            Alert(
                title: Text("Payment Error"),
                message: Text(viewModel.errorMessage),
                dismissButton: .default(Text("OK"))
            )
        }
        .withDeepBackground()
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
    }
} 