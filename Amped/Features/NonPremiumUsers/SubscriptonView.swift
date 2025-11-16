//
//  SubscriptonView.swift
//  Amped
//
//  Created by Shadeem Kazmi on 04/11/2025.
//

import SwiftUI

enum Plan: String, CaseIterable, Identifiable {
    case monthly = "Monthly"
    case yearly = "Yearly"

    var id: String { self.rawValue }

    var price: String {
        switch self {
        case .monthly: return "$4.99"
        case .yearly: return "$29.99"
        }
    }
}

// MARK: - Custom Navigation Bar
struct CustomNavigationBar: View {
    var body: some View {
        HStack {
            // Profile Icon and Name (Using SF Symbol as placeholder)
            Image(systemName: "person.circle.fill")
                .resizable()
                .frame(width: 32, height: 32)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.white.opacity(0.3), lineWidth: 1))
            Text("Adam John")
                .font(.headline)
                .foregroundColor(.white)
            
            Spacer()
            
            // Bell Icon
            Button(action: {}) {
                Image(systemName: "bell.fill")
                    .font(.title2)
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .padding(.horizontal, 10) // Small horizontal padding
        .padding(.top, 10)
        .padding(.bottom, 8) // Small spacing below the bar
        .background(Color(hex: "#1A1A1A").opacity(0.95))
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

// MARK: - Plan Card View (Resolves PlanCard Error)
struct PlanCard: View {
    let plan: Plan
    let isSelected: Bool
    let onSelect: () -> Void
    let gradientColors: [Color]

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(plan.rawValue)
                    .font(.title3)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : Color(hex: "#E0E0E0"))
                Text(plan.price)
                    .font(.caption)
                    .foregroundColor(isSelected ? .white.opacity(0.8) : Color(hex: "#B0B0B0"))
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


// MARK: - Main Subscription View
struct SubscriptionView: View {
    @State private var selectedPlan: Plan = .monthly
    
    let gradientColors = [Color(hex: "#0E8929"), Color(hex: "#18EF47")]
    let darkGrayBackground = Color(hex: "#1A1A1A")
    let lightGrayText = Color(hex: "#E0E0E0")
    
    @StateObject var store = StoreKitManager()
    var isFromOnboarding: Bool
    var onContinue: ((Bool) -> Void)?

    var body: some View {
        ZStack {
            darkGrayBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                
                // MARK: - Fixed Custom Navigation Bar (Header)
                if !isFromOnboarding {
                    CustomNavigationBar()
                        .padding(.bottom, 8)
                }
                
                // MARK: - Scrollable Content
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) { // Changed to .leading for better alignment
                        
                        // "Choose Your Plan" text
                        Text("Choose Your Plan")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(lightGrayText)
                            .padding(.horizontal) // Add padding to align with cards
                            .padding(.top, 16)
                        
                        // Subscription Plan Cards
                        HStack(spacing: 16) {
                            PlanCard(
                                plan: .monthly,
                                isSelected: selectedPlan == .monthly,
                                onSelect: { selectedPlan = .monthly },
                                gradientColors: gradientColors
                            )
                            PlanCard(
                                plan: .yearly,
                                isSelected: selectedPlan == .yearly,
                                onSelect: { selectedPlan = .yearly },
                                gradientColors: gradientColors
                            )
                        }
                        .padding(.horizontal)

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
                        .padding(.bottom, 120) // Add padding to ensure the last feature is visible above the fixed button
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                // MARK: - Fixed Subscribe Button (Footer)
                VStack(spacing: 8) {
                    
                        Button(action: {
                            // Handle subscribe action
                            print("Subscribing to \(selectedPlan.rawValue) plan.")
                            switch selectedPlan {
                            case .monthly:
                                if let monthly = store.products.first(where: { $0.isMonthly }) {
                                    Task {
                                        let result = await store.purchase(monthly)
                                        switch result {
                                        case .success(let _):
                                            onContinue?(true)
                                        case .cancelled:
                                            onContinue?(false)
                                        case .failed(let _):
                                            onContinue?(false)
                                        case .pending:
                                            onContinue?(false)
                                        }
                                    }
                                }
                            case .yearly:
                                if let yearly = store.products.first(where: { $0.isAnnual }) {
                                    Task {
                                        let result = await store.purchase(yearly)
                                            print(result)
                                    }
                                }
                            }
                        }) {
//                            NavigationLink(destination: PaymentMethodView()) {
                            Text("Subscribe")
                                .font(.title3)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    LinearGradient(
                                        colors: gradientColors.reversed(),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(100)
                                .padding(.horizontal)
//                        }
                            
                    }
                    
                    Button {
                        onContinue?(false)
                    } label: {
                        Text("Try for free")
                            .font(.poppins(20, weight: .medium))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .padding(.horizontal)
                    }

                }
                .background(darkGrayBackground)
                .padding(.bottom, 20)
            }
        }
    }
}

// MARK: - Preview
struct SubscriptionView_Previews: PreviewProvider {
    static var previews: some View {
//        SubscriptionView()
    }
}
