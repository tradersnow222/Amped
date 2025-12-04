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

    // MARK: - Adaptive Sizing (match MascotNamingView pattern)
    private var isPad: Bool { UIDevice.current.userInterfaceIdiom == .pad }
    private var contentMaxWidth: CGFloat { isPad ? 640 : .infinity }
    private var headerIconSize: CGFloat { isPad ? 24 : 20 }
    private var headerProfileSize: CGFloat { isPad ? 52 : 44 }
    private var headerTopPadding: CGFloat { isPad ? 10 : 5 }
    private var headerHorizontalPadding: CGFloat { isPad ? 28 : 16 }
    private var titleFontSize: CGFloat { isPad ? 26 : 20 }
    private var sectionSpacing: CGFloat { isPad ? 28 : 24 }
    private var cardSpacing: CGFloat { isPad ? 18 : 16 }
    private var productCardCorner: CGFloat { isPad ? 20 : 18 }
    private var featureTitleFontSize: CGFloat { isPad ? 18 : 16 }
    private var featureRowTitleFont: Font { .system(size: isPad ? 15 : 13, weight: .medium) }
    private var featureRowDescFont: Font { .system(size: isPad ? 13 : 11, weight: .regular) }
    private var ctaFontSize: CGFloat { isPad ? 22 : 20 }
    private var ctaVerticalPadding: CGFloat { isPad ? 12 : 8 }
    private var footerSpacing: CGFloat { isPad ? 20 : 18 }
    private var footerBottomPadding: CGFloat { isPad ? 20 : 5 }
    private var skipFontSize: CGFloat { isPad ? 18 : 16 }
    private var trialTextFontSize: CGFloat { isPad ? 14 : 12 }
    private var loaderFontSize: CGFloat { isPad ? 16 : 14 }
    private var featuresBottomPadding: CGFloat { isPad ? 160 : 120 }
    private var productGridColumns: [GridItem] {
        // Use 2 columns on iPad regular width; single column on iPhone
        isPad ? [GridItem(.flexible(), spacing: cardSpacing), GridItem(.flexible(), spacing: cardSpacing)] : [GridItem(.flexible())]
    }

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
                                .frame(width: headerIconSize, height: headerIconSize)
                        }
                        .padding(.leading)

                        ProfileImageView(size: headerProfileSize, showBorder: false, showEditIndicator: false, showWelcomeMessage: false)
                            .padding(.top, headerTopPadding)

                        Spacer()
                    }
                    .padding(.horizontal, headerHorizontalPadding)
                    .frame(maxWidth: .infinity)
                } else {
                    HStack(spacing: 10) {
                        Spacer()
                        Button {
                            onContinue?(false)
                        } label: {
                            Text("Skip")
                                .font(.poppins(skipFontSize, weight: .semibold))
                                .foregroundColor(.white)
                                .underline()
                        }
                        .padding(.horizontal, headerHorizontalPadding)
                        .padding(.vertical, isPad ? 12 : 8)
                    }
                    .frame(maxWidth: .infinity)
                }

                // MARK: Loader
                if store.isLoadingProducts {
                    VStack {
                        Spacer()
                        ProgressView("Loading plans...")
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .foregroundColor(.white)
                            .font(.system(size: loaderFontSize))
                        Spacer()
                    }
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: sectionSpacing) {
                            // Title
                            HStack {
                                Text("Choose Your Plan")
                                    .font(.poppins(titleFontSize, weight: .semibold))
                                    .foregroundColor(.white)
                                    .padding(.top, isPad ? 8 : 4)
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

                            // MARK: Features
                            featuresSection
                        }
                        .padding(.horizontal, isPad ? 40 : 16)
                        .padding(.top, isPad ? 12 : 0)
                        .frame(maxWidth: .infinity)
                    }
                    .onAppear {
                        if selectedProduct == nil {
                            selectedProduct = store.products.first
                        }
                    }
                    // Footer
                    subscriptionFooter
                        .frame(maxWidth: contentMaxWidth)
                        .padding(.horizontal, isPad ? 40 : 16)
                        .frame(maxWidth: .infinity)
                }
            }

            // MARK: Purchasing/Restoring Overlay
            if store.isPurchasing || store.isRestoring {
                ZStack {
                    Color.black
                        .opacity(0.7)
                        .ignoresSafeArea()

                    VStack {
                        Spacer()
                        ProgressView(store.isPurchasing ? "Processing purchase..." : "Restoring your purchase...")
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .foregroundColor(.white)
                            .font(.system(size: loaderFontSize))
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
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
        VStack(spacing: footerSpacing) {

            Button {
                guard let selectedProduct = selectedProduct else { return }

                if appState.isInTrial {
                    Task {
                        let result = await store.purchase(selectedProduct)
                        handleResult(result)
                    }
                } else {
                    appState.updateSubscriptionStatus(false, inTrial: true)
                    if isFromOnboarding {
                        onContinue?(true)
                    } else {
                        dismiss()
                    }
                }
            } label: {
                VStack(spacing: 4) {
                    Text(appState.isInTrial ? "Subscribe" : "Try for free")
                        .foregroundColor(.black)
                        .font(.poppins(ctaFontSize, weight: .medium))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, ctaVerticalPadding)
                .background(
                    LinearGradient(colors: gradientColors, startPoint: .leading, endPoint: .trailing)
                )
                .cornerRadius(100)
            }
            .disabled(selectedProduct == nil)

            Text(
                appState.isInTrial ? appState.formattedTrialExpiryStatus() : selectedProduct?.description ?? ""
            )
            .font(.poppins(trialTextFontSize, weight: .medium))
            .foregroundColor(.white).opacity(0.8)

            Button {
                Task {
                    let result = await store.restorePurchases()
                    handleRestoreResult(result)
                }
            } label: {
                Text("Restore")
                    .font(.poppins(isPad ? 20 : 18, weight: .medium))
                    .foregroundColor(.white)
            }
        }
        .padding(.bottom, footerBottomPadding)
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
        VStack(alignment: .leading, spacing: isPad ? 18 : 16) {
            Text("Amped Lifespan Premium Unlocks:")
                .font(.poppins(featureTitleFontSize, weight: .bold))
                .foregroundColor(.white)
                .padding(.bottom, isPad ? 6 : 4)

            FeatureRow(icon: "habbitIcon", title: "Habit Impact", description: "See how specific metrics affects your lifespan, minute by minute.")
            FeatureRow(icon: "insightIcon", title: "Deep Insights", description: "Track each habit’s historical impact across days, months, and years.")
            FeatureRow(icon: "lifeGainIcon", title: "Life Gain Plan", description: "Compare your current path vs optimal habits to see time gained.")
            FeatureRow(icon: "streakIcon", title: "Streaks", description: "Stay consistent and keep your life battery charged.")
            FeatureRow(icon: "smartIcon", title: "Smart Recommendations", description: "Get personalized ways to earn time back faster.")
        }
        .padding(.bottom, featuresBottomPadding)
    }
}

// MARK: - Plan Card
struct DynamicPlanCard: View {
    
    let product: RevenueCatProduct
    let isSelected: Bool
    let gradientColors: [Color]
    let onSelect: () -> Void

    private var isPad: Bool { UIDevice.current.userInterfaceIdiom == .pad }
    private var cornerRadius: CGFloat { isPad ? 20 : 18 }
    private var radioOuterSize: CGFloat { isPad ? 24 : 22 }
    private var radioInnerSize: CGFloat { isPad ? 14 : 12 }
    private var titleFont: Font { .system(size: isPad ? 18 : 16, weight: .medium) }
    private var priceFont: Font { .system(size: isPad ? 16 : 14, weight: .regular) }
    private var verticalPadding: CGFloat { isPad ? 20 : 18 }
    private var horizontalPadding: CGFloat { isPad ? 18 : 16 }

    var body: some View {
        VStack {
            // Perfect radio dot
            HStack {
                Spacer()
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.35), lineWidth: 1.5)
                        .frame(width: radioOuterSize, height: radioOuterSize)
                    
                    if isSelected {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: gradientColors,
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: radioInnerSize, height: radioInnerSize)
                    }
                }
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    
                    Text(product.displayName)
                        .font(titleFont)
                        .foregroundColor(
                            isSelected
                            ? Color(hex: "#18EF47")
                            : Color.white.opacity(0.95)
                        )
                    
                    Text(product.displayPrice)
                        .font(priceFont)
                        .foregroundColor(
                            isSelected
                            ? Color(hex: "#18EF47").opacity(0.8)
                            : Color.white.opacity(0.55)
                        )
                }
                Spacer()
            }
        }
        .padding(.horizontal, horizontalPadding)
        .padding(.vertical, verticalPadding)
        .background(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(
                            isSelected ?
                            AnyShapeStyle(
                                LinearGradient(colors: gradientColors,
                                               startPoint: .topLeading,
                                               endPoint: .bottomTrailing)
                            )
                            : AnyShapeStyle(Color.white.opacity(0.12)),
                            lineWidth: isSelected ? 1.5 : 1
                        )
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

    private var isPad: Bool { UIDevice.current.userInterfaceIdiom == .pad }
    private var iconSize: CGFloat { isPad ? 34 : 30 }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(icon)
                .font(.title2)
                .foregroundColor(Color(hex: "#18EF47"))
                .frame(width: iconSize, height: iconSize)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: isPad ? 15 : 13, weight: .medium))
                    .foregroundColor(.white)
                Text(description)
                    .font(.system(size: isPad ? 13 : 11, weight: .regular))
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
