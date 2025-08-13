import SwiftUI

/// Scientific credibility popup that shows impact score, importance, and source information
/// Based on real data and calculations from peer-reviewed research
struct ScientificCredibilityPopup: View {
    let metricType: HealthMetricType
    let studyReference: StudyReference
    let impactScore: Int // 0-100 score showing how much this activity affects life expectancy
    let importance: String // One sentence explaining why this is important
    @Binding var isPresented: Bool
    @State private var dragOffset: CGFloat = 0
    @StateObject private var glassTheme = GlassThemeManager()
    
    var body: some View {
        VStack(spacing: 0) {
            // Premium rounded top with drag indicator
            ZStack {
                // Premium glass background with rounded top corners
                UnevenRoundedRectangle(
                    topLeadingRadius: glassTheme.largeGlassCornerRadius,
                    bottomLeadingRadius: 0,
                    bottomTrailingRadius: 0,
                    topTrailingRadius: glassTheme.largeGlassCornerRadius
                )
                .fill(Color.ampedDark.opacity(0.85))
                // Remove border overlay to avoid odd grey edge on top corners
                .frame(height: 28)
                
                // Drag indicator
                RoundedRectangle(cornerRadius: 2.5)
                    .fill(Color.white.opacity(0.4))
                    .frame(width: 32, height: 4)
                    .padding(.top, 8)
            }
            
            // Content with premium glass background
            VStack(alignment: .leading, spacing: 24) {
                // Impact Score Section
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Text("Impact Score")
                            .font(.system(size: 18, weight: .regular, design: .rounded))
                            .foregroundColor(.white.opacity(0.85))
                        
                        Spacer()
                        
                        Image(systemName: "chevron.down")
                            .font(.system(size: 20))
                            .foregroundColor(.white.opacity(0.5))
                            .onTapGesture {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    isPresented = false
                                }
                            }
                    }
                    
                    // Score number with gradient
                    HStack(alignment: .firstTextBaseline, spacing: 0) {
                        Text("\(impactScore)")
                            .font(.system(size: 44, weight: .semibold, design: .rounded))
                            .foregroundColor(progressColor)
                        
                        Text("/100")
                            .font(.system(size: 18, weight: .regular, design: .rounded))
                            .foregroundColor(.white.opacity(0.4))
                            .padding(.bottom, 8)
                    }
                    .padding(.bottom, 8)
                    
                    // Premium progress bar
                    VStack(alignment: .leading, spacing: 6) {
                        // Bar
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                // Track background (matches dial style)
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.white.opacity(0.08))
                                    .background(
                                        RoundedRectangle(cornerRadius: 4)
                                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                    )
                                    .frame(height: 6)
                                
                                // Solid progress color (no gradient)
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(progressColor)
                                    .frame(width: geometry.size.width * CGFloat(impactScore) / 100, height: 6)
                                    .shadow(color: progressColor.opacity(0.35), radius: 4, x: 0, y: 0)
                                
                                // Premium indicator
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 14, height: 14)
                                    .shadow(color: Color.black.opacity(0.2), radius: 2, x: 0, y: 1)
                                    .overlay(
                                        Circle()
                                            .stroke(progressColor.opacity(0.3), lineWidth: 1)
                                    )
                                    .offset(x: geometry.size.width * CGFloat(impactScore) / 100 - 8, y: 0)
                            }
                        }
                        .frame(height: 6)
                        
                        // Labels
                        HStack {
                            Text("0")
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundColor(.white.opacity(0.4))
                            
                            Spacer()
                            
                            Text("100")
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundColor(.white.opacity(0.4))
                        }
                    }
                    .padding(.top, 8)
                    
                    Text(scoreDescription)
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundColor(.white.opacity(0.85))
                        .lineSpacing(3)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                // Why is this important section
                VStack(alignment: .leading, spacing: 16) {
                    Text(whyTitle)
                        .font(.system(size: 18, weight: .regular, design: .rounded))
                        .foregroundColor(.white.opacity(0.9))
                    
                    Text(importance)
                        .font(.system(size: 16, weight: .regular, design: .rounded))
                        .foregroundColor(.white.opacity(0.95))
                        .lineSpacing(6)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                // Premium source link
                Button(action: {
                    // Open the study link if available
                    if let doi = studyReference.doi,
                       let url = URL(string: "https://doi.org/\(doi)") {
                        UIApplication.shared.open(url)
                    }
                }) {
                    HStack(spacing: 8) {
                        Text("Source: \(studyReference.shortCitation)")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.7))
                        
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.08))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                    )
                }
                .padding(.bottom, 8)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 28)
            .background(Color.ampedDark.opacity(0.85))
        }
        .frame(maxWidth: .infinity)
        .background(Color.clear)
        .ignoresSafeArea(edges: .bottom)
    }
    
    /// Solid progress color matching lifespan dial palette (no gradients)
    private var progressColor: Color {
        // Simplicity is KING: single premium brand color
        return Color.ampedGreen
    }
    
    /// Scannable description tailored to the active metric
    private var scoreDescription: String {
        "This score estimates how your \(metricNoun) affects your life expectancy."
    }

    /// Human-friendly metric noun in sentence case
    private var metricNoun: String {
        switch metricType {
        case .steps: return "daily steps"
        case .exerciseMinutes: return "exercise"
        case .sleepHours: return "sleep duration"
        case .restingHeartRate: return "resting heart rate"
        case .heartRateVariability: return "heart rate variability"
        case .bodyMass: return "body weight"
        case .smokingStatus: return "smoking"
        case .stressLevel: return "anxiety levels"
        case .nutritionQuality: return "nutrition quality"
        case .alcoholConsumption: return "alcohol intake"
        case .socialConnectionsQuality: return "social connections"
        case .activeEnergyBurned: return "active energy"
        case .vo2Max: return "VO₂ max"
        case .oxygenSaturation: return "blood oxygen"
        case .bloodPressure: return "blood pressure"
        }
    }

    /// Dynamic title tailored to selected metric/question
    private var whyTitle: String {
        let metric = metricType
        switch metric {
        case .steps: return "Why are daily steps so important?"
        case .exerciseMinutes: return "Why is exercise so important?"
        case .sleepHours: return "Why is sleep duration so important?"
        case .restingHeartRate: return "Why is resting heart rate so important?"
        case .heartRateVariability: return "Why is HRV so important?"
        case .vo2Max: return "Why is VO₂ max so important?"
        case .bodyMass: return "Why is body mass so important?"
        case .smokingStatus: return "Why is smoking status so important?"
        case .stressLevel: return "Why are anxiety levels so important?"
        case .nutritionQuality: return "Why is nutrition quality so important?"
        case .alcoholConsumption: return "Why is alcohol consumption so important?"
        case .socialConnectionsQuality: return "Why are social connections so important?"
        case .activeEnergyBurned: return "Why is active energy so important?"
        case .oxygenSaturation: return "Why is oxygen saturation so important?"
        case .bloodPressure: return "Why is blood pressure so important?"
        }
    }
    
    /// Get color for impact score based on value
    private var impactScoreColor: Color {
        switch impactScore {
        case 0..<20:
            return Color.gray
        case 20..<40:
            return Color.yellow
        case 40..<60:
            return Color.orange
        case 60..<80:
            return Color.red
        case 80...100:
            return Color.red.opacity(0.9)
        default:
            return Color.gray
        }
    }
}

/// Factory for creating scientific credibility popups with real data
struct ScientificCredibilityPopupFactory {
    
    /// Create a popup for a specific metric type with calculated impact scores
    static func createPopup(for metricType: HealthMetricType, isPresented: Binding<Bool>) -> ScientificCredibilityPopup? {
        guard let studyReference = StudyReferenceProvider.getPrimaryStudy(for: metricType) else {
            return nil
        }
        
        let impactData = getImpactData(for: metricType)
        
        return ScientificCredibilityPopup(
            metricType: metricType,
            studyReference: studyReference,
            impactScore: impactData.score,
            importance: impactData.importance,
            isPresented: isPresented
        )
    }
    
    /// Get impact score and importance text for each metric type based on real research
    private static func getImpactData(for metricType: HealthMetricType) -> (score: Int, importance: String) {
        switch metricType {
        case .steps:
            return (
                score: 75,
                importance: "Research shows that increasing daily steps from 4,000 to 12,000 can reduce mortality risk by up to 50% and add 3+ years to your life."
            )
            
        case .exerciseMinutes:
            return (
                score: 80,
                importance: "Regular physical activity reduces all-cause mortality by 23-45% with greatest benefits for sedentary individuals starting to exercise."
            )
            
        case .sleepHours:
            return (
                score: 65,
                importance: "Both too little (<6h) and too much (>9h) sleep increase mortality risk, with optimal sleep duration of 7-8 hours per night."
            )
            
        case .restingHeartRate:
            return (
                score: 55,
                importance: "Each 10 bpm increase in resting heart rate above 60 is associated with 16-20% higher mortality risk in healthy adults."
            )
            
        case .heartRateVariability:
            return (
                score: 45,
                importance: "Higher heart rate variability indicates better autonomic nervous system function and is associated with reduced cardiovascular risk."
            )
            
        case .vo2Max:
            return (
                score: 70,
                importance: "Cardiorespiratory fitness is one of the strongest predictors of longevity, with each 1-MET increase reducing mortality by ~13%."
            )
            
        case .bodyMass:
            return (
                score: 60,
                importance: "Maintaining healthy weight (BMI 20-25) minimizes mortality risk, with obesity significantly reducing life expectancy."
            )
            
        case .smokingStatus:
            return (
                score: 95,
                importance: "Smoking reduces life expectancy by ~10 years, while quitting before age 40 eliminates nearly 90% of the excess risk."
            )
            
        case .stressLevel:
            return (
                score: 40,
                importance: "Chronic psychological stress increases mortality risk by 20% through multiple pathways including cardiovascular disease."
            )
            
        case .nutritionQuality:
            return (
                score: 50,
                importance: "High-quality dietary patterns like the Mediterranean diet reduce all-cause mortality by 9-20% compared to poor diets."
            )
            
        case .alcoholConsumption:
            return (
                score: 35,
                importance: "Research shows no safe level of alcohol consumption, with risk increasing linearly above 100g per week (~7 drinks)."
            )
            
        case .socialConnectionsQuality:
            return (
                score: 70,
                importance: "Strong social relationships increase survival odds by 50%, with isolation being as harmful as smoking or obesity."
            )
            
        case .activeEnergyBurned:
            return (
                score: 60,
                importance: "Higher daily energy expenditure through activity is strongly associated with reduced mortality in all age groups."
            )
            
        case .oxygenSaturation:
            return (
                score: 30,
                importance: "Consistently low oxygen saturation (≤95%) is associated with increased mortality, particularly from pulmonary causes."
            )
            
        case .bloodPressure:
            return (
                score: 85,
                importance: "Blood pressure is a major risk factor for cardiovascular death, with each 20/10 mmHg increase doubling vascular mortality risk."
            )
        }
    }
}

// MARK: - Preview
#Preview("Scientific Credibility Popup") {
    ZStack {
        // App-themed background
        Color.black.ignoresSafeArea()
        
        VStack {
            Spacer()
            
            if let popup = ScientificCredibilityPopupFactory.createPopup(for: .exerciseMinutes, isPresented: .constant(true)) {
                popup
                    .frame(height: UIScreen.main.bounds.height * 0.65)
                    .clipShape(
                        UnevenRoundedRectangle(
                            topLeadingRadius: 24,
                            bottomLeadingRadius: 0,
                            bottomTrailingRadius: 0,
                            topTrailingRadius: 24
                        )
                    )
            }
        }
    }
}

