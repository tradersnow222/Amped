import SwiftUI
import Foundation

/// Combined teaser screen shown right before the paywall.
/// It merges the preliminary battery score with credibility bullets
/// to subtly demonstrate value before requesting payment.
///
/// Applied rules: Simplicity is KING; keep file under 300 lines; MVVM-friendly; SwiftUI-first.
struct PrePaywallTeaserView: View {
    @ObservedObject var viewModel: QuestionnaireViewModel
    let onContinue: () -> Void

    // MARK: - Derived Values
    // Applied rules: Simplicity is KING; Keep file under 300 lines; Readability over extreme optimization
    @State private var dailyImpactMinutes: Double? = nil // Calculated from questionnaire answers only
    private var preliminaryScore: Int {
        var score = 50

        if let stressLevel = viewModel.selectedStressLevel {
            switch stressLevel {
            case .veryLow: score += 15
            case .low: score += 10
            case .moderateToHigh: score -= 5
            case .veryHigh: score -= 15
            }
        }

        if let nutritionQuality = viewModel.selectedNutritionQuality {
            switch nutritionQuality {
            case .veryHealthy: score += 15
            case .mostlyHealthy: score += 10
            case .mixedToUnhealthy: score -= 5
            case .veryUnhealthy: score -= 15
            }
        }

        if let smokingStatus = viewModel.selectedSmokingStatus {
            switch smokingStatus {
            case .never: score += 15
            case .former: score += 5
            case .occasionally: score -= 10
            case .daily: score -= 20
            }
        }

        if let alcoholFrequency = viewModel.selectedAlcoholFrequency {
            switch alcoholFrequency {
            case .never: score += 5
            case .occasionally: break
            case .severalTimesWeek: score -= 5
            case .dailyOrHeavy: score -= 15
            }
        }

        if let socialConnections = viewModel.selectedSocialConnectionsQuality {
            switch socialConnections {
            case .veryStrong: score += 10
            case .moderateToGood: score += 5
            case .limited: score -= 5
            case .isolated: score -= 10
            }
        }

        return max(0, min(100, score))
    }

    private var batteryColor: Color {
        switch preliminaryScore {
        case 80...100: return .ampedGreen
        case 60..<80: return .ampedYellow
        case 40..<60: return Color.orange
        case 20..<40: return .ampedRed
        default: return .red
        }
    }

    private var impactSummaryText: String {
        // Display a concise, personal summary based on the computed daily impact
        guard let minutes = dailyImpactMinutes else {
            return "Analyzing your answers so far…"
        }
        let isPositive = minutes >= 0
        let absMinutes = Int(round(abs(minutes)))
        let monthlyHours = abs(minutes) * 30.0 / 60.0
        let monthlyHoursString = String(format: "%.1f", monthlyHours)
        let direction = isPositive ? "gaining" : "losing"
        return "Based on your answers so far, you’re \(direction) \(absMinutes) min/day (≈ \(monthlyHoursString) hours/month)."
    }

    // MARK: - View
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color.black, Color.ampedDark.opacity(0.85)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 28) {
                Spacer(minLength: 16)

                Text("Your Preliminary Score")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)

                // Battery visualization
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(batteryColor, lineWidth: 4)
                        .frame(width: 120, height: 180)

                    VStack {
                        Spacer()
                        Rectangle()
                            .fill(batteryColor)
                            .frame(width: 112, height: 172 * CGFloat(preliminaryScore) / 100.0)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .frame(width: 112, height: 172)

                    RoundedRectangle(cornerRadius: 3)
                        .fill(batteryColor)
                        .frame(width: 36, height: 12)
                        .offset(y: -102)

                    Text("\(preliminaryScore)%")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                }
                .animation(.easeInOut(duration: 1.4), value: preliminaryScore)

                // Personal, actionable summary using actual calculation from questionnaire answers (no Health data yet)
                Text(impactSummaryText)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)

                VStack(alignment: .leading, spacing: 12) {
                    credibilityRow(text: "Built on peer‑reviewed research")
                    credibilityRow(text: "On‑device. Private by default")
                    credibilityRow(text: "This is from your answers so far — we’ll combine it with Apple Health next")
                    credibilityRow(text: "See the studies anytime in Settings → Research")
                }
                .padding(.horizontal, 40)

                Text("Amped turns your habits into time. Continue to see your full plan and next steps.")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.ampedGreen.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 36)
                    .padding(.top, 8)

                Spacer()

                Button(action: onContinue) {
                    Text("Continue")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(Color.ampedGreen)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .accessibilityIdentifier("prepaywall_continue")
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
            }
        }
        .task {
            // Compute actual total impact from questionnaire answers only
            // Rules referenced: Simplicity is KING; Correctness over speed; Avoid placeholders
            let manager = QuestionnaireManager()
            await manager.loadDataIfNeeded()
            if let profile = manager.getCurrentUserProfile() {
                let manualMetrics = manager.getCurrentManualMetrics().map { $0.toHealthMetric() }
                if !manualMetrics.isEmpty {
                    let service = LifeImpactService(userProfile: profile)
                    let total = service.calculateTotalImpact(from: manualMetrics, for: .day)
                    await MainActor.run { self.dailyImpactMinutes = total.totalImpactMinutes }
                }
            }
        }
    }

    // MARK: - Subviews
    private func credibilityRow(text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.ampedGreen)
            Text(text)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
            Spacer()
        }
    }
}

#Preview {
    PrePaywallTeaserView(
        viewModel: {
            let vm = QuestionnaireViewModel()
            vm.selectedStressLevel = .low
            vm.selectedNutritionQuality = .mostlyHealthy
            vm.selectedSmokingStatus = .never
            vm.selectedAlcoholFrequency = .occasionally
            vm.selectedSocialConnectionsQuality = .moderateToGood
            return vm
        }(),
        onContinue: {}
    )
}


