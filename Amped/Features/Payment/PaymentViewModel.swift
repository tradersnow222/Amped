import SwiftUI

/// ViewModel for payment screen
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
            self.appState?.completeOnboarding()
            
            // Continue to dashboard
            completion()
        }
    }
    
    // Process the discounted purchase
    func processPurchaseWithDiscount(completion: @escaping () -> Void) {
        isProcessing = true
        
        // Simulate network request
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.isProcessing = false
            
            // Mark onboarding as complete
            self.appState?.completeOnboarding()
            
            // Continue to dashboard
            completion()
        }
    }
    
    // Skip payment
    func skipPayment(completion: @escaping () -> Void) {
        // Mark onboarding as complete but without premium access
        appState?.completeOnboarding()
        
        // Continue to dashboard
        completion()
    }
    
    // Show discount popup (method that should be called by close button)
    func showDiscountOffer() {
        showDiscountPopup = true
    }
} 