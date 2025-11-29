//
//  SubscriptonView.swift
//  Amped
//
//  Created by Shadeem Kazmi on 04/11/2025.
//

import SwiftUI

struct SubscriptionView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var store: RevenueCatStoreKitManager
    @Environment(\.horizontalSizeClass) private var hSizeClass

    @State private var selectedProduct: RevenueCatProduct?
    @State private var showSuccessDialog = false
    @State private var showFailureDialog = false
    @State private var dialogMessageText = ""

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
                        Spacer()
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
                            
                            HStack {
                                Text("Choose Your Plan")
                                    .font(.poppins(20, weight: .semibold))
                                    .foregroundColor(.white)
                                    .padding(.top)
                                Spacer()
                            }.padding(.horizontal)
                            
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
                                .padding(.horizontal)
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
            if store.isPurchasing || store.isRestoring {
                ZStack {
                    Color.black
                        .opacity(0.7)
                        .ignoresSafeArea()   // covers full screen
                    
                    VStack {
                        Spacer()
                        
                        ProgressView(store.isPurchasing ? "Processing purchase..." : "Restoring your purchase...")
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .foregroundColor(.white)
                        
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity) // forces full size
                }
            }

            // Dialog content
            Group {
                if showSuccessDialog {
                    CustomDialogView(
                        emoji: "credit_cards",
                        message: dialogMessageText,
                        primaryTitle: "Okay",
                        secondaryTitle: "",
                        primaryIsDestructive: true,
                        onPrimary: {
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.95)) {
                                showSuccessDialog = false
                            }
                            if !isFromOnboarding {
                                dismiss()
                            }
                            onContinue?(true)
                        },
                        onCancel: {
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.95)) {
                                showSuccessDialog = false
                            }
                        }
                    )
                }
                if showFailureDialog {
                    CustomDialogView(
                        emoji: "crying_face",
                        message: dialogMessageText,
                        primaryTitle: "Okay",
                        secondaryTitle: "",
                        primaryIsDestructive: true,
                        onPrimary: {
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.95)) {
                                showFailureDialog = false
                            }
                            onContinue?(false)
                        },
                        onCancel: {
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.95)) {
                                showFailureDialog = false
                            }
                        }
                    )
                }
            }
            .transition(.scale.combined(with: .opacity))
            .zIndex(10)
        }
        .navigationBarBackButtonHidden(true)
        .task {
            store.appState = appState
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
//                    Text(selectedProduct?.description ?? "")
//                        .font(.poppins(12, weight: .medium))
//                        .foregroundColor(.white.opacity(0.7))
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

    // MARK: - Purchase Result Handler
    private func handleResult(_ result: RevenueCatStoreKitManager.PurchaseResult) {
        switch result {
        case .success:
            dialogMessageText = "Your subscription was activated successfully!"
            showSuccessDialog = true
            appState.updateSubscriptionStatus(true)

        case .cancelled:
            dialogMessageText = "Purchase was cancelled. No charges were made."
            showFailureDialog = true
            appState.updateSubscriptionStatus(false)

        case .failed:
            dialogMessageText = "Your purchase failed. Please try again."
            showFailureDialog = true
            appState.updateSubscriptionStatus(false)

        case .pending:
            dialogMessageText = "Your purchase is pending approval. You’ll be notified once it’s completed."
            showFailureDialog = true
            appState.updateSubscriptionStatus(false)
        }
    }

    // MARK: - Restore Result Handler
    private func handleRestoreResult(_ result: RevenueCatStoreKitManager.RestoreResult) {
        switch result {
        case .success:
            dialogMessageText = "Your previous subscription has been successfully restored."
            showSuccessDialog = true
            appState.updateSubscriptionStatus(true)

        case .failed:
            dialogMessageText = "We couldn’t restore your purchases. Please try again later."
            showFailureDialog = true
            appState.updateSubscriptionStatus(false)

        case .noValidTransactions:
            dialogMessageText = "No previous purchases were found for your account."
            showFailureDialog = true
            appState.updateSubscriptionStatus(false)
        }
    }

    // MARK: Features
    private var featuresSection: some View {
        // Your Subscription Unlocks section
        VStack(alignment: .leading, spacing: 16) {
            Text("Amped Lifespan Premium Unlocks:")
                .font(.poppins(16, weight: .bold))
                .foregroundColor(.white)
                .padding(.bottom, 4)

            FeatureRow(icon: "habbitIcon", title: "Habit Impact", description: "SSee how specific metrics affects your lifespan, minute by minute.")
            FeatureRow(icon: "insightIcon", title: "Deep Insights", description: "Track each habit’s historical impact across days, months, and years.")
            FeatureRow(icon: "lifeGainIcon", title: "Life Gain Plan", description: "Compare your current path vs optimal habits to see time gained.")
            FeatureRow(icon: "streakIcon", title: "Streaks", description: "Stay consistent and keep your life battery charged.")
            FeatureRow(icon: "smartIcon", title: "Smart Recommendations", description: "Get personalized ways to earn time back faster.")
        }
        .padding(.bottom, 120)
    }
}

struct DynamicPlanCard: View {
    
    let product: RevenueCatProduct
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
            Spacer()
        }
    }
}

// MARK: - Preview
struct SubscriptionView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            SubscriptionView(isFromOnboarding: false)
                .environmentObject(AppState())
                .environmentObject(RevenueCatStoreKitManager())
                .previewDisplayName("iPhone")
                .previewDevice("iPhone 15 Pro")
            
            SubscriptionView(isFromOnboarding: false)
                .environmentObject(AppState())
                .environmentObject(RevenueCatStoreKitManager())
                .previewDisplayName("iPad")
                .previewDevice("iPad Pro (11-inch) (4th generation)")
        }
    }
}
