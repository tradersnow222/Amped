//
//  mainReasonStatsView.swift
//  Amped
//
//  Created by Yawar Abbas   on 03/11/2025.
//

import SwiftUI

struct MainReasonStatsView: View {
    @EnvironmentObject private var appState: AppState

    var isFromSettings: Bool = false
    @State private var selectedStressLevel: StressLevel? = nil
    let progress: Double = 13
    var onContinue: ((String) -> Void)?
    var onSelection: ((String) -> Void)?
    var onBack: (() -> Void)?
    
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
    
    @State private var showSheet = false
    
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
                    
                    Text("100%")
                        .font(.poppins(12))
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(.bottom, 30)

                VStack(spacing: 8) {
                    Text("What is the main reason you might want to live longer?")
                        .font(.poppins(18, weight: .medium))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .truncationMode(.tail)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 40)
                }
                .padding(.top, 8)

                // Stress Level Buttons
                VStack(spacing: 16) {
                    ForEach(StressLevel.allCases, id: \.self) { level in
                        Button(action: {
                            onSelection?(level.rawValue)
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedStressLevel = level
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

                OnboardingContinueButton(
                    title: "Continue",
                    isEnabled: selectedStressLevel != nil,
                    animateIn: true,
                    bottomPadding: 20
                ) {
                    guard let selectedStressLevel else { return }
                    onContinue?(selectedStressLevel.rawValue)
                }
                
                // Research info text (use as an info trigger)
                HStack(spacing: 8) {
                    Image(systemName: "book.closed")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.5))
                    
                    Button {
                        showSheet.toggle()
                    } label: {
                        Text("See how your current habits impact your lifespan.")
                            .font(.poppins(13, weight: .regular))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 20)
            }
        }
        .overlay(content: {
            BottomSheet(isPresented: $showSheet) {
                AggregateImpactSheetContent()
            }
        })
        .navigationBarBackButtonHidden(false)
        .onAppear {
            // If launched from Settings, prefill from defaults
            if isFromSettings {
                let saved = appState.getFromUserDefault(key: UserDefaultsKeys.userMainReasonStats)
                if !saved.isEmpty {
                    selectedStressLevel = StressLevel(rawValue: saved)
                }
            }
        }
    }
}

// MARK: - Aggregate life impact BottomSheet content (uses all current manual metrics)

private struct AggregateImpactSheetContent: View {
    @State private var score: Int = 50
    @State private var sliderValue: Double = 50
    @State private var descriptionText: String = "Loading..."
    @State private var sourceText: String = "Based on your current manual metrics"
    @State private var title: String = "Impact score: Your current habits"
    
    var body: some View {
        ImpactContentView(
            title: title,
            score: score,
            maxScore: 100,
            sliderValue: sliderValue,
            descriptionText: descriptionText,
            sourceText: sourceText
        )
        .onAppear {
            Task { await load() }
        }
    }
    
    private func loadUserProfile() -> UserProfile {
        if let data = UserDefaults.standard.data(forKey: "user_profile"),
           let profile = try? JSONDecoder().decode(UserProfile.self, from: data) {
            return profile
        }
        let currentYear = Calendar.current.component(.year, from: Date())
        return UserProfile(id: UUID().uuidString, birthYear: currentYear - 30, gender: .male, isSubscribed: false, hasCompletedOnboarding: false, hasCompletedQuestionnaire: false, hasGrantedHealthKitPermissions: false, createdAt: Date(), lastActive: Date())
    }
    
    private func normalizeImpactToScore(_ minutesPerDay: Double) -> Int {
        let clamped = max(-120.0, min(120.0, minutesPerDay))
        let normalized = (clamped + 120.0) / 240.0
        return Int((normalized * 100.0).rounded())
    }
    
    private func load() async {
        let profile = loadUserProfile()
        let qm = QuestionnaireManager()
        let lifeService = LifeImpactService(userProfile: profile)
        
        // Build metrics from current manual inputs
        let manualInputs = qm.getCurrentManualMetrics()
        let metrics: [HealthMetric] = manualInputs.map {
            HealthMetric(id: UUID().uuidString, type: $0.type, value: $0.value, date: $0.date, source: .userInput)
        }
        
        // Calculate total daily impact (use .day period)
        let impactPoint = lifeService.calculateTotalImpact(from: metrics, for: .day)
        let dailyMinutes = impactPoint.totalImpactMinutes
        
        // Prepare a friendly description
        let formatted = ImpactDataPoint.formatLifespanImpact(minutes: dailyMinutes)
        let summary = "Estimated total daily impact from your current habits: \(formatted)."
        
        await MainActor.run {
            let s = normalizeImpactToScore(dailyMinutes)
            self.score = max(0, min(100, s))
            self.sliderValue = Double(self.score)
            self.descriptionText = summary
            self.sourceText = "Aggregated from your current manual inputs"
        }
    }
}

