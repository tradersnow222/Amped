import SwiftUI
import StoreKit

/// Payment screen with subscription options
struct PaymentView: View {
    // MARK: - Properties
    
    @StateObject private var viewModel = PaymentViewModel()
    @EnvironmentObject var appState: AppState
    
    // Callback to proceed to next step
    var onContinue: (() -> Void)?
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 20) {
            // Title
            Text("Fully Power Up")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top, 40)
            
            // Description
            Text("Choose your plan to unlock full battery potential")
                .font(.headline)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)
            
            // Premium benefits
            VStack(alignment: .leading, spacing: 16) {
                Text("Premium Benefits")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top)
                
                benefitRow(icon: "chart.bar.fill", text: "Advanced health metrics and analytics")
                benefitRow(icon: "waveform.path.ecg", text: "Detailed heart rate and HRV analysis")
                benefitRow(icon: "chart.line.uptrend.xyaxis", text: "Unlimited historical data access")
                benefitRow(icon: "bell.fill", text: "Custom alerts and battery notifications")
                benefitRow(icon: "bolt.fill", text: "Priority battery recharging tips")
            }
            .padding(.horizontal, 30)
            .padding(.vertical, 20)
            
            Spacer()
            
            // Subscription options
            VStack(spacing: 16) {
                // Monthly plan
                subscriptionOption(
                    title: "Monthly",
                    price: "$4.99",
                    period: "month",
                    isSelected: viewModel.selectedPlan == .monthly,
                    action: { viewModel.selectedPlan = .monthly }
                )
                
                // Annual plan (with discount)
                subscriptionOption(
                    title: "Annual",
                    price: "$39.99",
                    period: "year",
                    discount: "Save 33%",
                    isSelected: viewModel.selectedPlan == .annual,
                    isBestValue: true,
                    action: { viewModel.selectedPlan = .annual }
                )
                
                // Lifetime plan
                subscriptionOption(
                    title: "Lifetime",
                    price: "$99.99",
                    period: "one-time",
                    isSelected: viewModel.selectedPlan == .lifetime,
                    action: { viewModel.selectedPlan = .lifetime }
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
                Text("Continue")
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.ampedGreen)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.horizontal, 30)
            
            Button("Continue with Free Version") {
                skipPayment()
            }
            .font(.subheadline)
            .foregroundColor(.secondary)
            .padding(.top, 10)
            
            // Progress indicator
            ProgressIndicator(currentStep: 6, totalSteps: 7)
                .padding(.vertical, 30)
        }
        .overlay(
            Group {
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
            }
        )
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
        // In a real app, we would use StoreKit to process the purchase
        viewModel.isProcessing = true
        
        // Simulate network request
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            viewModel.isProcessing = false
            
            // Complete onboarding
            appState.hasCompletedOnboarding = true
            
            // Continue to dashboard
            onContinue?()
        }
    }
    
    private func skipPayment() {
        // Mark onboarding as complete but without premium access
        appState.hasCompletedOnboarding = true
        
        // Continue to dashboard
        onContinue?()
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
                    
                    Text("\(price) / \(period)")
                        .font(.subheadline)
                }
                
                Spacer()
                
                if let discount = discount {
                    Text(discount)
                        .font(.caption)
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
    }
}

// MARK: - ViewModel

final class PaymentViewModel: ObservableObject {
    // Subscription plans
    enum SubscriptionPlan {
        case monthly
        case annual
        case lifetime
    }
    
    // UI states
    @Published var selectedPlan: SubscriptionPlan = .annual
    @Published var isProcessing = false
    @Published var showError = false
    @Published var errorMessage = ""
}

// MARK: - Preview

struct PaymentView_Previews: PreviewProvider {
    static var previews: some View {
        PaymentView(onContinue: {})
            .environmentObject(AppState())
    }
} 