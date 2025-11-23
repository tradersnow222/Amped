//
//  DietStatsView.swift
//  Amped
//
//  Created by Yawar Abbas   on 03/11/2025.
//

import SwiftUI

struct DietStatsView: View {
    @EnvironmentObject private var appState: AppState

    var isFromSettings: Bool = false
    @State private var selectedStressLevel: StressLevel? = nil
    let progress: Double = 8
    var onContinue: ((String) -> Void)?
    var onSelection: ((String) -> Void)?
    var onBack: (() -> Void)?
    
    @State private var showSheet = false
    
    enum StressLevel: String, CaseIterable {
        case low = "Very Healthy"
        case moderate = "Mixed"
        case high = "Very unhealthy"
        
        var subtitle: String {
            switch self {
            case .low:
                return "(whole foods, plant-based)"
            case .moderate:
                return "(balanced diet)"
            case .high:
                return "(fast food, highly processed)"
            }
        }
    }
    
    var body: some View {
        ZStack {
            LinearGradient.customBlueToDarkGray
                .ignoresSafeArea()

            VStack(spacing: 24) {
                
                HStack {
                    Button(action: {
                        // back action
                        onBack?()
                    }) {
                        Image("backIcon")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                    }
                    .padding(.leading, 30)
                    .padding(.top, 10)
                    
                    Spacer() // pushes button to leading
                }
                
                // Top mascot image
                Image("battery")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .shadow(color: Color.green.opacity(0.35), radius: 18, x: 0, y: 6)
                    .padding(.top, 25)

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
                    
                    Text("56%")
                        .font(.poppins(12))
                        .foregroundColor(.white.opacity(0.8))
                    
                    Text("How would you describe your \ntypical diet?")
                        .font(.poppins(18, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.top, 45)
                }
                .padding(.bottom, 30)

                // Stress Level Buttons
                VStack(spacing: 16) {
                    ForEach(StressLevel.allCases, id: \.self) { level in
                        Button(action: {
                            onSelection?(level.rawValue)
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedStressLevel = level
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

                OnboardingContinueButton(
                    title: "Continue",
                    isEnabled: selectedStressLevel != nil,
                    animateIn: true,
                    bottomPadding: 40
                ) {
                    guard let selectedStressLevel else { return }
                    onContinue?(selectedStressLevel.rawValue)
                }
                
                // Research info text
                HStack(spacing: 8) {
                    Image(systemName: "book.closed")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.5))
                    
                    Button {
                        showSheet.toggle()
                    } label: {
                        
                        Text("Tap to see what research based on 195 studies tell us.")
                            .font(.poppins(13, weight: .regular))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
                .padding(.horizontal, 32)
                .padding(.top, 8)

                Spacer()
            }
        }
        .overlay(content: {
            BottomSheet(isPresented: $showSheet) {
                MetricImpactSheetContent(metricType: .nutritionQuality, customTitle: "Impact score: Diet")
            }
        })
        .navigationBarBackButtonHidden(false)
        .onAppear {
            // If launched from Settings, prefill from defaults
            if isFromSettings {
                let saved = appState.getFromUserDefault(key: UserDefaultsKeys.userDietLevel)
                if !saved.isEmpty {
                    selectedStressLevel = StressLevel(rawValue: saved)
                }
            }
        }
    }
}

#Preview {
    DietStatsView()
}
