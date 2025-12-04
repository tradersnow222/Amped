//
//  BloodPressureReading.swift
//  Amped
//
//  Created by Yawar Abbas   on 03/11/2025.
//

import SwiftUI

struct BloodPressureReadingView: View {
    @EnvironmentObject private var appState: AppState

    var isFromSettings: Bool = false
    @State private var selectedStressLevel: StressLevel? = nil
    let progress: Double = 12
    var onContinue: ((String) -> Void)?
    var onSelection: ((String) -> Void)?
    var onBack: (() -> Void)?
    
    @State private var showSheet = false
    
    private var isPad: Bool { UIDevice.current.userInterfaceIdiom == .pad }
    private var mascotSize: CGFloat { isPad ? 180 : 120 }
    private var titleSize: CGFloat { isPad ? 34 : 26 }
    private var progressHeight: CGFloat { isPad ? 16 : 12 }
    private var progressTextSize: CGFloat { isPad ? 14 : 12 }
    private var questionFontSize: CGFloat { isPad ? 20 : 18 }
    private var optionTitleSize: CGFloat { isPad ? 20 : 18 }
    private var optionSubtitleSize: CGFloat { isPad ? 15 : 13 }
    private var optionHeight: CGFloat { isPad ? 60 : 54 }
    private var backIconSize: CGFloat { isPad ? 24 : 20 }
    
    enum StressLevel: String, CaseIterable {
        case low = "Below 120/80"
        case moderate = "130/80+"
        case high = "I don’t know"
        
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
            LinearGradient.customBlueToDarkGray
                .ignoresSafeArea()

            VStack(spacing: isPad ? 28 : 24) {
                
                HStack {
                    Button(action: {
                        onBack?()
                    }) {
                        Image("backIcon")
                            .resizable()
                            .scaledToFit()
                            .frame(width: backIconSize, height: backIconSize)
                    }
                    .padding(.leading, 30)
                    .padding(.top, isPad ? 16 : 10)
                    
                    Spacer()
                }
                
                Image("Amped_8")
                    .resizable()
                    .scaledToFit()
                    .frame(width: mascotSize, height: mascotSize)
                    .shadow(color: Color.green.opacity(0.35), radius: isPad ? 18 : 18, x: 0, y: 6)
                    .padding(.top, isPad ? 28 : 25)

                Text("Let's get familiar!")
                    .font(.poppins(titleSize, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.top, 4)

                VStack(spacing: 4) {
                    ProgressView(value: progress, total: 13)
                        .progressViewStyle(ThickProgressViewStyle(height: progressHeight))
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, isPad ? 60 : 40)
                    
                    Text("91%")
                        .font(.poppins(progressTextSize))
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(.bottom, isPad ? 28 : 30)

                VStack(spacing: 8) {
                    Text("What is your typical blood pressure reading?")
                        .font(.poppins(questionFontSize, weight: .medium))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .truncationMode(.tail)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, isPad ? 60 : 40)
                }
                .padding(.top, 8)

                VStack(spacing: 16) {
                    ForEach(StressLevel.allCases, id: \.self) { level in
                        Button(action: {
                            onSelection?(level.rawValue)
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedStressLevel = level
                                guard let selectedStressLevel else { return }
                                onContinue?(selectedStressLevel.rawValue)
                            }
                        }) {
                            VStack(spacing: 1) {
                                Text(level.rawValue)
                                    .font(.poppins(optionTitleSize, weight: .semibold))
                                    .foregroundColor(selectedStressLevel == level ? .white : .white.opacity(0.9))
                                    .multilineTextAlignment(.center)
                                
                                if !level.subtitle.isEmpty {
                                    Text(level.subtitle)
                                        .font(.poppins(optionSubtitleSize, weight: .regular))
                                        .foregroundColor(selectedStressLevel == level ? .white.opacity(0.9) : .white.opacity(0.6))
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: optionHeight)
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

                HStack(spacing: 8) {
                    Image(systemName: "book.closed")
                        .font(.system(size: isPad ? 16 : 14))
                        .foregroundColor(.white.opacity(0.5))
                    
                    Button {
                        showSheet.toggle()
                    } label: {
                        Text("Tap to see what research based on 195 studies tell us.")
                            .font(.poppins(isPad ? 14 : 13, weight: .regular))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
                .padding(.horizontal, 32)
                .padding(.top, 8)
                
                Spacer()
            }
        }
        .sheet(isPresented: $showSheet) {
            MetricImpactSheetContent(metricType: .bloodPressure, customTitle: "Impact score: Blood Pressure")
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .navigationBarBackButtonHidden(false)
        .onAppear {
            if isFromSettings {
                let saved = appState.getFromUserDefault(key: UserDefaultsKeys.userBloodPressureStats)
                if !saved.isEmpty {
                    selectedStressLevel = StressLevel(rawValue: saved)
                }
            }
        }
    }
}
