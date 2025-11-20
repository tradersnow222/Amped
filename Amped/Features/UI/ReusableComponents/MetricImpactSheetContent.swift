//
//  MetricImpactSheetContent.swift
//  Amped
//
//  Created by Sheraz Hussain on 21/11/2025.
//

import SwiftUI

struct MetricImpactSheetContent: View {
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
        // Reasonable default
        let currentYear = Calendar.current.component(.year, from: Date())
        return UserProfile(id: UUID().uuidString, birthYear: currentYear - 30, gender: .male, isSubscribed: false, hasCompletedOnboarding: false, hasCompletedQuestionnaire: false, hasGrantedHealthKitPermissions: false, createdAt: Date(), lastActive: Date())
    }
    
    private func currentManualValue(for type: HealthMetricType) -> Double? {
        let qm = QuestionnaireManager()
        let inputs = qm.getCurrentManualMetrics()
        return inputs.first(where: { $0.type == type })?.value
    }
    
    private func normalizeImpactToScore(_ minutesPerDay: Double) -> Int {
        // Map -120...+120 min/day to 0...100
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
        // If no manual input exists yet, fall back to baseline for a neutral message
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

