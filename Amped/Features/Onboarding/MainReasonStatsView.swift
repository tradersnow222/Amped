//
//  mainReasonStatsView.swift
//  Amped
//
//  Created by Yawar Abbas   on 03/11/2025.
//

import SwiftUI

struct MainReasonStatsView: View {
    @State private var selectedStressLevel: StressLevel? = nil
    let progress: Double = 0.39
    var onContinue: ((String) -> Void)?
    
    enum StressLevel: String, CaseIterable {
        case low = "Watch my family grow"
        case moderate = "Achieve my dreams"
        case high = "Simply to experience life longer"
        
        var subtitle: String {
            switch self {
            case .low:
                return ""
            case .moderate:
                return ""
            case .high:
                return ""
            }
        }
    }
    
    var body: some View {
        ZStack {
            LinearGradient.grayGradient
                .ignoresSafeArea()

            VStack(spacing: 24) {
                // Top mascot image
                Image("battery")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .shadow(color: Color.green.opacity(0.35), radius: 18, x: 0, y: 6)
                    .padding(.top, 48)

                Text("Let's get familiar!")
                    .font(.poppins(26, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.top, 4)

                // Progress with percentage below
                VStack(spacing: 6) {
                    GeometryReader { proxy in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.white.opacity(0.15))
                                .frame(height: 10)

                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [Color(hex: "#18EF47"), Color(hex: "#0E8929")],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: max(0, min(proxy.size.width * progress, proxy.size.width)), height: 10)
                        }
                    }
                    .frame(height: 10)
                    .padding(.horizontal, 40)

                    Text("100%")
                        .font(.poppins(12))
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(.bottom, 8)

                VStack(spacing: 8) {
                    Text("What is the main reason you might want \nto live longer?")
                        .font(.poppins(18, weight: .medium))
                        .foregroundColor(.white)
                    
//                    Text("typical stress level?")
//                        .font(.poppins(18, weight: .medium))
//                        .foregroundColor(.white)
                }
                .padding(.top, 8)

                // Stress Level Buttons
                VStack(spacing: 16) {
                    ForEach(StressLevel.allCases, id: \.self) { level in
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedStressLevel = level
                            }
                            // Auto continue after selection
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                onContinue?(level.rawValue)
                            }
                        }) {
                            VStack(spacing: 1) {
                                Text(level.rawValue)
                                    .font(.poppins(18, weight: .semibold))
                                    .foregroundColor(selectedStressLevel == level ? .white : .white.opacity(0.9))
                                    .multilineTextAlignment(.center)
                                
                                // Subtitle (only show if not empty)
                                    if !level.subtitle.isEmpty {
                                        Text(level.subtitle)
                                            .font(.poppins(13, weight: .regular))
                                            .foregroundColor(selectedStressLevel == level ? .white.opacity(0.9) : .white.opacity(0.6))
                                    }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(
                                Group {
                                    if selectedStressLevel == level {
                                        LinearGradient(
                                            colors: [Color(hex: "#18EF47"), Color(hex: "#0E8929")],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    } else {
                                        Color.white.opacity(0.08)
                                    }
                                }
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 35, style: .continuous)
                                    .stroke(Color(hex: "#18EF47").opacity(selectedStressLevel == level ? 0 : 0.6), lineWidth: 1)
                            )
                            .cornerRadius(35)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 32)
                .padding(.top, 16)

                // Research info text
                HStack(spacing: 8) {
                    Image(systemName: "book.closed")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.5))
                    
                    Text("Tap to see what research based on 195 studies tell us.")
                        .font(.poppins(13, weight: .regular))
                        .foregroundColor(.white.opacity(0.5))
                }
                .padding(.horizontal, 32)
                .padding(.top, 8)

                Spacer()
            }
        }
        .navigationBarBackButtonHidden(false)
    }
}
