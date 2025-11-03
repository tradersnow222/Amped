//
//  AnxietyStats.swift
//  Amped
//
//  Created by Yawar Abbas   on 03/11/2025.
//

import SwiftUI

struct AnxietyStatsView: View {
    @State private var selectedStressLevel: StressLevel? = nil
    let progress: Double = 7
    var onContinue: ((String) -> Void)?
    
    enum StressLevel: String, CaseIterable {
        case low = "Mild"
        case moderate = "Moderate"
        case high = "Severe"
        
        var subtitle: String {
            switch self {
            case .low:
                return "(rarely feel anxious)"
            case .moderate:
                return "(Frequent anxiety episodes)"
            case .high:
                return "(Frequent anxiety episodes)"
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

                // MARK: - Progress Bar
                VStack(spacing: 4) {
                    ProgressView(value: progress, total: 13)
                        .progressViewStyle(ThickProgressViewStyle(height: 12))
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 40)
                    
                    Text("47%")
                        .font(.poppins(12))
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(.bottom, 30)

                VStack(spacing: 8) {
                    Text("How would you describe your")
                        .font(.poppins(18, weight: .medium))
                        .foregroundColor(.white)
                    
                    Text(" anxiety level?")
                        .font(.poppins(18, weight: .medium))
                        .foregroundColor(.white)
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
                            VStack(spacing: 4) {
                                Text(level.rawValue)
                                    .font(.poppins(18, weight: .semibold))
                                    .foregroundColor(selectedStressLevel == level ? .white : .white.opacity(0.9))
                                
                                Text(level.subtitle)
                                    .font(.poppins(13, weight: .regular))
                                    .foregroundColor(selectedStressLevel == level ? .white.opacity(0.9) : .white.opacity(0.6))
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
