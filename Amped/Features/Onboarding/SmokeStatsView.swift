//
//  SmokeStatsView.swift
//  Amped
//
//  Created by Yawar Abbas   on 03/11/2025.
//

import SwiftUI

struct SmokeStatsView: View {
    @State private var selectedStressLevel: StressLevel? = nil
    let progress: Double = 9
    var onContinue: ((String) -> Void)?
    var onBack: (() -> Void)?
    
    @State private var showSheet = false
    
    enum StressLevel: String, CaseIterable {
        case low = "Never"
        case moderate = "Former smoker"
        case high = "Daily"
        
        var subtitle: String {
            switch self {
            case .low:
                return ""
            case .moderate:
                return "(quit in the past)"
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
                    
                    Text("65%")
                        .font(.poppins(12))
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(.bottom, 30)

                VStack(spacing: 8) {
                    Text("Do you smoke tobaccos \nproducts?")
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
                MetricImpactSheetContent(metricType: .smokingStatus, customTitle: "Impact score: Smoke Tobacco")
            }
        })
        .navigationBarBackButtonHidden(false)
    }
}

// MARK: - Real data BottomSheet content

private struct MetricImpactSheetContent: View {
    let metricType: HealthMetricType
    var customTitle: String? = nil
    
    @State private var score: Int = 50
    @State private var sliderValue: Double = 50
    @State private var descriptionText: String = "Loading..."
    @State private var sourceText: String = "Loading source..."
    @State private var title: String = ""
    
    var body: some View {
        ImpactContentView(
            title: title.isEmpty ? (customTitle ?? "Impact score: \(metricType.displayName)") : title,
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
    
    private func currentManualValue(for type: HealthMetricType) -> Double? {
        let qm = QuestionnaireManager()
        let inputs = qm.getCurrentManualMetrics()
        return inputs.first(where: { $0.type == type })?.value
    }
    
    private func normalizeImpactToScore(_ minutesPerDay: Double) -> Int {
        let clamped = max(-120.0, min(120.0, minutesPerDay))
        let normalized = (clamped + 120.0) / 240.0
        return Int((normalized * 100.0).rounded())
    }
    
    private func composeDescription(metric: HealthMetric, impact: MetricImpactDetail) -> String {
        let formattedImpact = impact.formattedImpactWithConfidence
        let recommendation = impact.recommendation
        return "Current: \(metric.formattedValue)\(metric.unitString.isEmpty ? "" : " \(metric.unitString)")\n\(formattedImpact).\n\(recommendation)"
    }
    
    private func sourceString(from impact: MetricImpactDetail) -> String {
        impact.scientificBasis
    }
    
    private func computeTitle() -> String {
        customTitle ?? "Impact score: \(metricType.displayName)"
    }
    
    private func metricForCurrentValue(_ value: Double) -> HealthMetric {
        HealthMetric(
            id: UUID().uuidString,
            type: metricType,
            value: value,
            date: Date(),
            source: .userInput
        )
    }
    
    private func fallbackValue() -> Double {
        return metricType.baselineValue
    }
    
    private func formatScore(_ s: Int) -> Int { max(0, min(100, s)) }
    
    private func updateUI(metric: HealthMetric, impact: MetricImpactDetail) {
        let s = normalizeImpactToScore(impact.lifespanImpactMinutes)
        self.title = computeTitle()
        self.score = formatScore(s)
        self.sliderValue = Double(self.score)
        self.descriptionText = composeDescription(metric: metric, impact: impact)
        self.sourceText = sourceString(from: impact)
    }
    
    private func load() async {
        let profile = loadUserProfile()
        let lifeService = LifeImpactService(userProfile: profile)
        
        let value = currentManualValue(for: metricType) ?? fallbackValue()
        var metric = metricForCurrentValue(value)
        let impact = lifeService.calculateImpact(for: metric)
        metric.impactDetails = impact
        
        await MainActor.run {
            updateUI(metric: metric, impact: impact)
        }
    }
}

