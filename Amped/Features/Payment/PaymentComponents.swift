import SwiftUI

/// UI components for the Payment screen
struct PaymentComponents {
    
    /// Benefit row with icon and text
    struct BenefitRow: View {
        let icon: String
        let text: String
        
        var body: some View {
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
    }
    
    /// Subscription option button
    struct SubscriptionOption: View {
        let title: String
        let price: String
        let discountedPrice: String?
        let period: String
        let discount: String?
        let isSelected: Bool
        let isBestValue: Bool
        let action: () -> Void
        
        init(
            title: String,
            price: String,
            discountedPrice: String? = nil,
            period: String,
            discount: String? = nil,
            isSelected: Bool,
            isBestValue: Bool = false,
            action: @escaping () -> Void
        ) {
            self.title = title
            self.price = price
            self.discountedPrice = discountedPrice
            self.period = period
            self.discount = discount
            self.isSelected = isSelected
            self.isBestValue = isBestValue
            self.action = action
        }
        
        var body: some View {
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
    
    /// Discount popup view
    struct DiscountPopup: View {
        @ObservedObject var viewModel: PaymentViewModel
        let onContinue: (() -> Void)?
        
        var body: some View {
            ZStack {
                Color.black.opacity(0.4)
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                        // Dismiss by tapping outside
                        // viewModel.showDiscountPopup = false
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
                            // viewModel.showDiscountPopup = false
                            viewModel.skipPayment {
                                onContinue?()
                            }
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
                             // viewModel.showDiscountPopup = false
                              viewModel.processPurchase {
                                  onContinue?()
                              }
                          }) {
                            Text("Accept Offer")
                                .fontWeight(.bold)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.ampedGreen)
                                .foregroundColor(.white)
                                .cornerRadius(14)
                        }
                        .hapticFeedback(.heavy)
                    }
                    .padding(.top, 10)
                }
                .padding(30)
                .background(Color.cardBackground)
                .cornerRadius(20)
                .shadow(radius: 20)
                .padding(.horizontal, 30)
            }
            .transition(.opacity)
            .onAppear {
                // Remove the popup functionality - not needed for clean payment flow
                // viewModel.showDiscountPopup = false
            }
        }
    }
    
    /// Processing overlay
    struct ProcessingOverlay: View {
        var body: some View {
            ZStack {
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
                .background(Color.cardBackground)
                .cornerRadius(10)
            }
        }
    }
} 