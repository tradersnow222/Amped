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
                    .foregroundColor(themeManager.currentTheme.textColor)
                
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
                    
                    benefitRow(icon: "chart.bar.fill", text: "Advanced health metrics and analytics")
                    benefitRow(icon: "waveform.path.ecg", text: "Detailed heart rate and HRV analysis")
                    benefitRow(icon: "chart.line.uptrend.xyaxis", text: "Unlimited historical data access")
                    benefitRow(icon: "bell.fill", text: "Custom alerts and battery notifications")
                    benefitRow(icon: "bolt.fill", text: "Priority battery recharging tips")
                }
                .padding(.horizontal, 30)
                
                Spacer()
                
                // Subscription options
                VStack(spacing: 16) {
                    // Yearly plan (with discount)
                    subscriptionOption(
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
                    subscriptionOption(
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
                Color.black.opacity(0.4)
                    .edgesIgnoringSafeArea(.all)
                
                VStack {
                    ProgressView()
                        .scaleEffect(1.5)
                        .padding()
                    
                    Text("Processing...")
                        .font(.headline)
                        .foregroundColor(.white)
                }
                .padding(30)
                .background(Color(.systemBackground).opacity(0.8))
                .cornerRadius(10)
            }
            
            // Discount popup
            if viewModel.showDiscountPopup {
                ZStack {
                    Color.black.opacity(0.4)
                        .edgesIgnoringSafeArea(.all)
                        .onTapGesture {
                            // Dismiss by tapping outside
                            viewModel.showDiscountPopup = false
                        }
                    
                    VStack(spacing: 20) {
                        Text("Looking for a deal? We've got you covered!")
                            .font(.headline)
                            .multilineTextAlignment(.center)
                            .padding(.top)
                        
                        Text("Special offer: Get 50% off your first year!")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.ampedGreen)
                            .multilineTextAlignment(.center)
                        
                        Text("$19.99")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        + Text(" ")
                        
                        Text("$39.99")
                            .font(.headline)
                            .strikethrough()
                        
                        Text("for the first year")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 20) {
                            // Decline
                            Button(action: {
                                viewModel.showDiscountPopup = false
                                viewModel.skipPayment()
                            }) {
                                Text("No thanks")
                                    .fontWeight(.medium)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color(.systemGray5))
                                    .foregroundColor(.primary)
                                    .cornerRadius(14)
                            }
                            .hapticFeedback(.light)
                            
                            // Accept
                            Button(action: {
                                viewModel.showDiscountPopup = false
                                viewModel.processPurchaseWithDiscount()
                            }) {
                                Text("Accept Offer")
                                    .fontWeight(.bold)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.ampedGreen)
                                    .foregroundColor(.white)
                                    .cornerRadius(14)
                            }
                            .successFeedback()
                        }
                        .padding(.top, 10)
                    }
                    .padding(30)
                    .background(Color(.systemBackground))
                    .cornerRadius(20)
                    .shadow(radius: 20)
                    .padding(.horizontal, 30)
                }
                .transition(.opacity)
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
    
    // MARK: - UI Components
    
    /// Benefit row with icon and text
    private func benefitRow(icon: String, text: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundColor(.ampedGreen)
                .frame(width: 30, height: 30)
            
            Text(text)
                .font(.body)
            
            Spacer()
        }
    }
    
    /// Subscription option button
    private func subscriptionOption(
        title: String,
        price: String,
        discountedPrice: String? = nil,
        period: String,
        discount: String? = nil,
        isSelected: Bool,
        isBestValue: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                    
                    if let discountedPrice = discountedPrice {
                        HStack(spacing: 4) {
                            Text(price)
                                .font(.title3)
                                .fontWeight(.bold)
                            
                            Text(discountedPrice)
                                .font(.subheadline)
                                .strikethrough()
                                .foregroundColor(.secondary)
                        }
                    } else {
                        Text(price)
                            .font(.title3)
                            .fontWeight(.bold)
                    }
                    
                    Text("per \(period)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if let discount = discount {
                    Text(discount)
                        .font(.caption)
                        .fontWeight(.bold)
                        .padding(6)
                        .background(Color.ampedGreen)
                        .foregroundColor(.white)
                        .cornerRadius(4)
                }
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(isSelected ? .ampedGreen : .gray)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isBestValue ? Color.ampedGreen : Color.gray.opacity(0.5), lineWidth: isSelected ? 2 : 1)
            )
            .overlay(
                Group {
                    if isBestValue {
                        VStack {
                            Text("Best Value")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.ampedGreen)
                                .cornerRadius(4)
                                .offset(y: -10)
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .offset(y: -10)
                    }
                }
            )
        }
        .foregroundColor(.primary)
        .hapticFeedback(.selection)
    }
}

// MARK: - ViewModel

final class PaymentViewModel: ObservableObject {
    enum SubscriptionPlan {
        case monthly
        case annual
    }
    
    // State tracking
    @Published var selectedPlan: SubscriptionPlan = .annual
    @Published var isProcessing: Bool = false
    @Published var showError: Bool = false
    @Published var showDiscountPopup: Bool = false
    @Published var errorMessage: String = ""
    
    // Injected app state
    @Published var appState: AppState?
    
    // Process the purchase
    func processPurchase(completion: @escaping () -> Void) {
        isProcessing = true
        
        // Simulate network request
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.isProcessing = false
            
            // Mark onboarding as complete
            self.appState?.hasCompletedOnboarding = true
            
            // Continue to dashboard
            completion()
        }
    }
    
    // Process the discounted purchase
    func processPurchaseWithDiscount() {
        isProcessing = true
        
        // Simulate network request
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.isProcessing = false
            
            // Mark onboarding as complete
            self.appState?.hasCompletedOnboarding = true
        }
    }
    
    // Skip payment
    func skipPayment() {
        // Mark onboarding as complete but without premium access
        appState?.hasCompletedOnboarding = true
    }
}

// MARK: - Preview

struct PaymentView_Previews: PreviewProvider {
    static var previews: some View {
        PaymentView(onContinue: {})
    }
} 