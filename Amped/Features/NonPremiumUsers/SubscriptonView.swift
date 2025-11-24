//
//  SubscriptonView.swift
//  Amped
//
//  Created by Shadeem Kazmi on 04/11/2025.
//

import SwiftUI
import StoreKit

struct SubscriptionView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject var store = StoreKitManager()

    @State private var selectedProduct: Product?

    let gradientColors = [Color(hex: "#0E8929"), Color(hex: "#18EF47")]
    let darkGrayBackground = Color(hex: "#1A1A1A")
    let lightGrayText = Color(hex: "#E0E0E0")

    var isFromOnboarding: Bool
    var onContinue: ((Bool) -> Void)?

    var body: some View {
        ZStack {
            LinearGradient.customBlueToDarkGray
                .ignoresSafeArea()

            VStack(spacing: 0) {

                // MARK: Header
                if !isFromOnboarding {
                    HStack(spacing: 10) {
                        Button {
                            dismiss()
                        } label: {
                            Image("backIcon")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 20, height: 20)
                        }
                        .padding(.leading)
                        ProfileImageView(size: 44, showBorder: false, showEditIndicator: false, showWelcomeMessage: false)
                            .padding(.top,5)
                    }
                }

                // MARK: Loader
                if store.isLoadingProducts {
                    VStack {
                        Spacer()
                        
                        ProgressView("Loading plans...")
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .foregroundColor(.white)
                        
                        Spacer()
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 24) {
                            
                            Text("Choose Your Plan")
                                .font(.title2.bold())
                                .foregroundColor(.white)
                                .padding(.top)
                            
                            // MARK: Dynamic Product Cards
                            HStack(spacing: 16) {
                                ForEach(store.products, id: \.id) { product in
                                    DynamicPlanCard(
                                        product: product,
                                        isSelected: selectedProduct?.id == product.id,
                                        gradientColors: gradientColors
                                    ) {
                                        selectedProduct = product
                                    }
                                }
                            }
                            .padding(.horizontal)
                            
                            featuresSection
                        }
                    }
                    .onAppear {
                        if selectedProduct == nil {
                            selectedProduct = store.products.first
                        }
                    }
                    // Footer
                    subscriptionFooter
                }
            }
            // MARK: Loader
            if store.isPurchasing {
                VStack {
                    Spacer()
                    
                    ProgressView("Processing purchase...")
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .foregroundColor(.white)
                    
                    Spacer()
                }
            }
            if store.isRestoring {
                VStack {
                    Spacer()
                    
                    ProgressView("Restoring your purchase...")
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .foregroundColor(.white)
                    
                    Spacer()
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .task {
            if selectedProduct == nil {
                selectedProduct = store.products.first
            }
        }
    }

    // MARK: Footer
    private var subscriptionFooter: some View {
        VStack(spacing: 18) {

            Button {
                guard let selectedProduct = selectedProduct else { return }

                Task {
                    let result = await store.purchase(selectedProduct)
                    handleResult(result)
                }
            } label: {
                VStack(spacing: 0) {
                    Text("Subscribe")
                        .foregroundColor(.black)
                        .font(.poppins(20, weight: .medium))
                    Text(selectedProduct?.description ?? "Test")
                        .font(.poppins(12, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(
                    LinearGradient(colors: gradientColors, startPoint: .leading, endPoint: .trailing)
                )
                .cornerRadius(100)
                .padding(.horizontal)
            }
            .disabled(selectedProduct == nil)

            Button {
                onContinue?(false)
            } label: {
                Text("Try for free")
                    .font(.poppins(18, weight: .medium))
                    .foregroundColor(.white)
            }
            
            Button {
                Task {
                    let result = await store.restorePurchases()
                    handleRestoreResult(result)
                }
            } label: {
                Text("Restore")
                    .font(.poppins(18, weight: .medium))
                    .foregroundColor(.white)
            }
        }
        .padding(.bottom, 5)
    }

    // MARK: Purchase Result Handler
    private func handleResult(_ result: StoreKitManager.PurchaseResult) {
        switch result {
        case .success:
            onContinue?(true)
        case .cancelled, .failed, .pending:
            onContinue?(false)
        }
    }
    
    private func handleRestoreResult(_ result: StoreKitManager.RestoreResult) {
        switch result {
        case .success:
            onContinue?(true)
        case .failed:
            onContinue?(false)
        case .noValidTransactions:
            onContinue?(false)
        }
    }

    // MARK: Features
    private var featuresSection: some View {
        // Your Subscription Unlocks section
        VStack(alignment: .leading, spacing: 16) {
            Text("Your Subscription Unlocks:")
                .font(.headline)
                .fontWeight(.medium)
                .foregroundColor(lightGrayText)
                .padding(.bottom, 4)

            FeatureRow(icon: "habbitIcon", title: "Habit Impact", description: "SSee how specific metrics affects your lifespan, minute by minute.")
            FeatureRow(icon: "insightIcon", title: "Deep Insights", description: "Track each habit’s historical impact across days, months, and years.")
            FeatureRow(icon: "lifeGainIcon", title: "Life Gain Plan", description: "Compare your current path vs optimal habits to see time gained.")
            FeatureRow(icon: "streakIcon", title: "Streaks", description: "Stay consistent and keep your life battery charged.")
            FeatureRow(icon: "smartIcon", title: "Smart Recommendations", description: "Get personalized ways to earn time back faster.")
        }
        .padding(.horizontal)
        .padding(.bottom, 120)
    }
}

struct DynamicPlanCard: View {
    
    let product: Product
    let isSelected: Bool
    let gradientColors: [Color]
    let onSelect: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                
                Text(product.displayName)
                    .foregroundColor(.white)
                    .font(.headline)
                
                Text(product.displayPrice)
                    .foregroundColor(.white.opacity(0.7))
                    .font(.subheadline)
            }
            
            Spacer()
            
            // Custom radio button style
            Circle()
                .stroke(isSelected ? .clear : Color.white.opacity(0.3), lineWidth: 1)
                .background(
                    LinearGradient(
                        colors: isSelected ? gradientColors : [Color.white.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 20, height: 20)
                .cornerRadius(10)
        }
        .frame(
            minWidth: 160,
            maxWidth: .infinity,
            minHeight: 100
        )
        .padding(EdgeInsets(top: 14, leading: 12, bottom: 14, trailing: 12))
        .frame(maxWidth: .infinity)
        .background(Color(hex: "#2C2C2C"))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
            // Fix: Use AnyShapeStyle or a single-color LinearGradient for type matching
                .stroke(
                    isSelected
                    ? AnyShapeStyle(LinearGradient(colors: gradientColors, startPoint: .topLeading, endPoint: .bottomTrailing))
                    : AnyShapeStyle(Color.clear),
                    lineWidth: 1
                )
        )
        .onTapGesture(perform: onSelect)
    }
}


// MARK: - Feature Row View (Resolves FeatureRow Error)
struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(icon)
                .font(.title2)
                .foregroundColor(Color(hex: "#18EF47")) // Green color for icons
                .frame(width: 30, height: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
        }
    }
}

// MARK: - Preview
struct SubscriptionView_Previews: PreviewProvider {
    static var previews: some View {
        SubscriptionView(isFromOnboarding: false)
    }
}
