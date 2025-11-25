//
//  PremiumUnlockView.swift
//  Amped
//
//  Created by Yawar Abbas   on 15/11/2025.
//

import SwiftUI

struct PremiumFeature: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let subtitle: String
}

struct PaywallScreen: View {
    
    var onContinue: ((Bool) -> Void)?
    
    private let features: [PremiumFeature] = [
        PremiumFeature(icon: "habbitIcon", title: "Habit Impact", subtitle: "See how specific metrics affects your lifespan, minute by minute."),
        PremiumFeature(icon: "insightIcon", title: "Deep Insights", subtitle: "Track each habit’s historical impact across days, months, and years."),
        PremiumFeature(icon: "lifeGainIcon", title: "Life Gain Plan", subtitle: "Compare your current path vs optimal habits to see time gained."),
        PremiumFeature(icon: "streakIcon", title: "Streaks", subtitle: "Stay consistent and keep your life battery charged."),
        PremiumFeature(icon: "smartIcon", title: "Smart Recommendations", subtitle: "Get personalized ways to earn time back faster.")
    ]
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 20/255, green: 32/255, blue: 51/255),
                    Color(red: 36/255, green: 44/255, blue: 57/255)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    
                    // Skip Button
                    HStack {
                        Spacer()
                        Button("Skip") {
                            onContinue?(false)
                        }
                            .foregroundColor(.white.opacity(0.7))
                            .padding(.top, 10)
                            .padding(.trailing, 20)
                    }
                    
                    // Mascot Image
                    Image("Amped_8") 
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120)
                        .padding(.top, -30)

                    // Title
                    VStack(spacing: 8) {
                        Text("Hey, Adam! Turn your habits into more time with Amped Premium")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 30)
                    }
                    
                    // Feature Section
                    VStack(spacing: 20) {
                        Text("Amped Lifespan Premium Unlocks:")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 24)

                        VStack(spacing: 16) {
                            ForEach(features) { feature in
                                FeaturesRow(feature: feature)
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                    
                    // CTA Button
                    Button(action: {
                        onContinue?(false)
                    }) {
                        Text("Try for free")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.black)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(
                                LinearGradient(
                                    colors: [Color.green.opacity(0.9), Color.green],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .cornerRadius(40)
                            .padding(.horizontal, 24)
                    }
                    .padding(.top, 10)
                    
                    Button {
                        onContinue?(true)
                    } label: {
                        // Price Info
                        Text("3 days free, then $29.99/year.")
                            .foregroundColor(.white.opacity(0.7))
                            .font(.system(size: 14))
                            .padding(.bottom, 30)
                    }
                }
            }
        }
    }
}

struct FeaturesRow: View {
    let feature: PremiumFeature
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 46, height: 46)
                
                Image(feature.icon)
                    .foregroundColor(.white)
                    .font(.system(size: 20))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(feature.title)
                    .foregroundColor(.white)
                    .font(.system(size: 17, weight: .semibold))

                Text(feature.subtitle)
                    .foregroundColor(.white.opacity(0.7))
                    .font(.system(size: 14))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct PaywallScreen_Previews: PreviewProvider {
    static var previews: some View {
        PaywallScreen()
    }
}
