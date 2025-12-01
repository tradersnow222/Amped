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
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var score: Int = 50
    @State private var sliderValue: Double = 50
    @State private var descriptionText: String = "Loading..."
    @State private var sourceText: String = "Loading source..."
    @State private var title: String = ""
    
    // New: hold a tappable URL for the primary study reference
    @State private var sourceURL: URL?
    @State private var safariURL: URL?
    
    var body: some View {
        ZStack {
            // Custom dark background so content looks correct in both light and dark device modes
            Color.black.ignoresSafeArea(.all).opacity(0.3)
            
            VStack(spacing: 0) {
                // Header with grabber and close button
                ZStack {
                    HStack {
                        Spacer()
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white.opacity(0.9))
                                .padding(12)
                                .contentShape(Rectangle())
                        }
                        .accessibilityLabel("Close")
                    }
                    
                    // Visible grabber that works on dark bg
//                    Capsule()
//                        .fill(Color.white.opacity(0.35))
//                        .frame(width: 64, height: 6)
//                        .padding(.vertical, 8)
                }
                .padding(.horizontal, 8)
                .padding(.top, 4)
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        // Title
                        Text(title.isEmpty ? (customTitle ?? "Impact score: \(metricType.displayName)") : title)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white.opacity(0.9))
                            .padding(.top, 4)
                        
                        // Big score "50/100"
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text("\(score)")
                                .font(.system(size: 44, weight: .semibold))
                                .foregroundColor(.white)
                            Text("/100")
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundColor(.white.opacity(0.5))
                        }
                        
                        // Slider (read-only)
                        VStack(spacing: 6) {
                            AmpedProgressSlider(value: sliderValue / 100.0)
                                .frame(height: 28)
                            HStack {
                                Text("0")
                                    .font(.system(size: 12, weight: .regular))
                                    .foregroundColor(.white.opacity(0.6))
                                Spacer()
                                Text("100")
                                    .font(.system(size: 12, weight: .regular))
                                    .foregroundColor(.white.opacity(0.6))
                            }
                        }
                        .padding(.top, 2)
                        
                        // Description paragraphs (first regular, second bold, third regular)
                        VStack(alignment: .leading, spacing: 16) {
                            let paragraphs = styledParagraphs(from: descriptionText)
                            ForEach(paragraphs.indices, id: \.self) { idx in
                                let p = paragraphs[idx]
                                Text(p.text)
                                    .font(.system(size: 16, weight: p.isEmphasized ? .semibold : .regular))
                                    .foregroundColor(.white.opacity(0.9))
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        
                        // Source chip
                        if let sourceURL, !sourceText.isEmpty {
                            Button {
                                safariURL = sourceURL
                            } label: {
                                HStack(spacing: 8) {
                                    Text(sourceText)
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(.white.opacity(0.9))
                                        .lineLimit(1)
                                        .truncationMode(.tail)
                                    Image(systemName: "arrow.up.right")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(.white.opacity(0.9))
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .fill(Color.white.opacity(0.12))
                                )
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(Text("Open source: \(sourceText)"))
                            .padding(.top, 4)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
                }
                .scrollContentBackground(.hidden) // avoid default system background bleed
            }
        }
        .onAppear {
            Task { await load() }
        }
        // In-app Safari presentation
        .sheet(item: $safariURL) { url in
            SafariView(url: url)
                .ignoresSafeArea()
        }
        // Ensure the system sheet background doesn’t overlay our dark gradient (iOS 17+)
//        .presentationBackground(.clear)
        // Force a dark look for this sheet so white text has consistent contrast
        .preferredColorScheme(.dark)
        // Improve corner radius appearance against our gradient
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
    
    // MARK: - Data loading and composition
    
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
    
    // Compose 3 paragraphs to match the screenshot layout
    private func composeDescription(metric: HealthMetric, impact: MetricImpactDetail) -> String {
        // 1) Plain explainer
        let intro = "This score estimates how your \(metric.type.displayName.lowercased()) affects your life expectancy."
        // 2) Emphasized takeaway using the score for clarity
        let emphasis = "\(metric.type.displayName) contributes to \(max(0, min(100, normalizeImpactToScore(impact.lifespanImpactMinutes))))% of your total lifespan impact. It’s important!"
        // 3) Supporting recommendation from research
        let supporting = impact.recommendation
        return [intro, emphasis, supporting].joined(separator: "\n")
    }
    
    private func sourceString(from impact: MetricImpactDetail) -> String {
        // Prefer the first study’s short citation if available
        if let first = impact.studyReferences.first {
            return "Source: \(first.shortCitation)"
        }
        return impact.scientificBasis
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
        self.sourceURL = primaryURL(from: impact)
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
    
    // MARK: - URL helpers
    
    private func primaryURL(from impact: MetricImpactDetail) -> URL? {
        guard let first = impact.studyReferences.first else { return nil }
        if let doi = first.doi, let url = URL(string: "https://doi.org/\(doi)") {
            return url
        }
        if let pmid = first.pmid, let url = URL(string: "https://pubmed.ncbi.nlm.nih.gov/\(pmid)/") {
            return url
        }
        return nil
    }
    
    // MARK: - Text helpers
    
    private struct Paragraph {
        let text: String
        let isEmphasized: Bool
    }
    
    private func styledParagraphs(from raw: String) -> [Paragraph] {
        // Split by newlines and style second paragraph as emphasized to match screenshot
        let parts = raw
            .replacingOccurrences(of: "\r\n", with: "\n")
            .components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        return parts.enumerated().map { idx, t in
            Paragraph(text: t, isEmphasized: idx == 1)
        }
    }
}

// MARK: - Lightweight progress slider that visually matches the screenshot
private struct AmpedProgressSlider: View {
    let value: Double // 0...1
    
    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let progressWidth = max(0, min(width, width * value))
            
            ZStack(alignment: .leading) {
                // Max track (white)
                Capsule()
                    .fill(Color.white.opacity(0.7))
                    .frame(height: 4)
                
                // Min track (amped green)
                Capsule()
                    .fill(Color("ampedGreen"))
                    .frame(width: progressWidth, height: 4)
                
                // Thumb
                Circle()
                    .fill(Color.white)
                    .frame(width: 24, height: 24)
                    .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
                    .overlay(
                        Circle()
                            .stroke(Color.black.opacity(0.15), lineWidth: 0.5)
                    )
                    .position(x: max(12, min(width - 12, progressWidth)), y: 14)
            }
        }
    }
}
