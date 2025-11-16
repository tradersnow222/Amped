//
//  PaymentMethodView.swift
//  Amped
//
//  Created by Shadeem Kazmi on 04/11/2025.
//
import SwiftUI
// MARK: - PaymentMethodView
struct PaymentMethodView: View {
    @Environment(\.presentationMode) var presentationMode // To dismiss the view

    @State private var selectedPaymentMethod: String? = nil // To track selection

    let darkGrayBackground = Color(hex: "#1A1A1A")
    let lightGrayText = Color(hex: "#E0E0E0")
    let buttonGradientColors = [Color(hex: "#18EF47"), Color(hex: "#0E8929")] // Green gradient

    var body: some View {
        ZStack {
            darkGrayBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                // MARK: - Custom Navigation Bar (with Back Button)
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss() // Dismiss this view
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    Spacer()
                    Image(systemName: "person.circle.fill") // Placeholder
                        .resizable()
                        .frame(width: 32, height: 32)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.white.opacity(0.3), lineWidth: 1))
                    Text("Adam John")
                        .font(.headline)
                        .foregroundColor(.white)
                    Spacer()
                    Button(action: {}) {
                        Image(systemName: "bell.fill")
                            .font(.title2)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                .padding(.horizontal)
                .padding(.top, 50)
                .background(Color(hex: "#1A1A1A").opacity(0.95))
                .padding(.bottom, 8)

                // MARK: - Main Content
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        Text("Please select payment method you\nwant to continue with.")
                            .font(.title3)
                            .foregroundColor(lightGrayText)
                            .padding(.horizontal)
                            .padding(.top, 16)

                        // MARK: - Payment Options List
                        VStack(spacing: 12) {
                            PaymentOptionRow(
                                icon: Image("paypal_icon"), // Replace with actual asset
                                title: "PayPal",
                                isSelected: selectedPaymentMethod == "PayPal",
                                onSelect: { selectedPaymentMethod = "PayPal" }
                            )
                            PaymentOptionRow(
                                icon: Image("google_pay_icon"), // Replace with actual asset
                                title: "Google Pay",
                                isSelected: selectedPaymentMethod == "Google Pay",
                                onSelect: { selectedPaymentMethod = "Google Pay" }
                            )
                            PaymentOptionRow(
                                icon: Image("apple_pay_icon"), // Replace with actual asset
                                title: "Apple Pay",
                                isSelected: selectedPaymentMethod == "Apple Pay",
                                onSelect: { selectedPaymentMethod = "Apple Pay" }
                            )
                            PaymentOptionRow(
                                icon: Image(systemName: "plus.circle.fill"), // SF Symbol for "Add"
                                title: "Add New Card",
                                isSelected: selectedPaymentMethod == "Add New Card",
                                onSelect: { selectedPaymentMethod = "Add New Card" }
                            )
                        }
                        .padding(.horizontal)

                        Spacer()
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                // MARK: - Fixed Continue Button
                VStack(spacing: 8) {
                    Button(action: {
                        // Handle continue action with selectedPaymentMethod
                        print("Continuing with: \(selectedPaymentMethod ?? "No method selected")")
                    }) {
                        HStack {
                            Text("Continue")
                                .font(.title3)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                            Image(systemName: "arrow.right")
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: buttonGradientColors,
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(20)
                        .padding(.horizontal)
                    }

                    // Paywall Text (matches the bottom bar look)
                    HStack(spacing: 12) {
                        Image(systemName: "creditcard")
                            .foregroundColor(Color(hex: "#B0B0B0"))
                        Text("Paywall")
                            .font(.caption)
                            .foregroundColor(Color(hex: "#B0B0B0"))
                    }
                    .padding(.bottom, 10)
                }
                .background(darkGrayBackground)
                .padding(.bottom, 20)
            }
        }
        .navigationBarHidden(true) // Hide default navigation for custom bar
    }
}

// MARK: - Payment Option Row
struct PaymentOptionRow: View {
    let icon: Image // Can be SF Symbol or Asset Image
    let title: String
    let isSelected: Bool
    let onSelect: () -> Void

    let borderColor = Color(hex: "#3FA9F5") // Blue border for selected state

    var body: some View {
        HStack(spacing: 12) {
            icon
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 24, height: 24)
                .foregroundColor(title == "Add New Card" ? Color(hex: "#18EF47") : nil) // Green for Add New Card
            
            Text(title)
                .font(.headline)
                .foregroundColor(.white)

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundColor(.white.opacity(0.6))
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 20)
        .background(Color(hex: "#2C2C2C")) // Darker background for rows
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isSelected ? borderColor : Color.clear, lineWidth: 1)
        )
        .onTapGesture(perform: onSelect)
    }
}

// MARK: - Placeholder Images for Payment Options (for Preview)
extension Image {
    static var paypal_icon: Image { Image(systemName: "p.circle.fill") }
    static var google_pay_icon: Image { Image(systemName: "g.circle.fill") }
    static var apple_pay_icon: Image { Image(systemName: "apple.logo") }
}

// MARK: - Preview
struct PaymentMethodView_Previews: PreviewProvider {
    static var previews: some View {
        PaymentMethodView()
    }
}
