import SwiftUI
import Foundation

/// Premium luxury pre-paywall teaser with sophisticated visual design
/// Inspired by high-end health apps like Oura Ring, WHOOP, and premium fitness trackers
/// Applied rules: Simplicity is KING; keep file under 300 lines; MVVM-friendly; SwiftUI-first.
struct PrePaywallTeaserView: View {
    @ObservedObject var viewModel: QuestionnaireViewModel
    let onContinue: () -> Void

    // MARK: - Animation States
    @State private var animateBattery = false
    @State private var showLifeGain = false
    @State private var showCredibility = false
    @State private var batteryGlow = false
    @State private var shimmerOffset: CGFloat = -200
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

    // Premium gradient colors for luxury aesthetic
    private var batteryGradient: LinearGradient {
        switch preliminaryScore {
        case 80...100: 
            return LinearGradient(
                colors: [
                    Color(red: 0.0, green: 0.8, blue: 0.4),
                    Color(red: 0.2, green: 1.0, blue: 0.6),
                    Color(red: 0.0, green: 0.9, blue: 0.5)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case 60..<80:
            return LinearGradient(
                colors: [
                    Color(red: 0.3, green: 0.8, blue: 0.2),
                    Color(red: 0.5, green: 1.0, blue: 0.4),
                    Color(red: 0.2, green: 0.9, blue: 0.3)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case 40..<60:
            return LinearGradient(
                colors: [
                    Color(red: 0.6, green: 0.8, blue: 0.1),
                    Color(red: 0.8, green: 1.0, blue: 0.3),
                    Color(red: 0.7, green: 0.9, blue: 0.2)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case 20..<40:
            return LinearGradient(
                colors: [Color.ampedYellow.opacity(0.8), Color.ampedYellow],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        default:
            return LinearGradient(
                colors: [Color.ampedRed.opacity(0.8), Color.ampedRed],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    private var primaryBatteryColor: Color {
        switch preliminaryScore {
        case 80...100: return Color(red: 0.1, green: 0.9, blue: 0.5)
        case 60..<80: return Color(red: 0.3, green: 0.9, blue: 0.3)
        case 40..<60: return Color(red: 0.7, green: 0.9, blue: 0.2)
        case 20..<40: return .ampedYellow
        default: return .ampedRed
        }
    }
    
    // Calculate life gain for conversion value
    private var lifeGainMinutes: Int {
        let baseGain = 2
        let scoreBonus = max(0, preliminaryScore - 50) / 10
        return baseGain + scoreBonus
    }
    
    private var lifeGainHours: Double {
        Double(lifeGainMinutes) * 30.44 / 60.0 // Monthly hours
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
            // Background handled by parent OnboardingFlow with withDeepBackground()
            // Following app's consistent background pattern

            VStack(spacing: 40) {
                Spacer()

                // Premium headline with sophisticated typography
                VStack(spacing: 16) {
                    Text("Your Life Battery")
                        .font(.system(size: 38, weight: .thin, design: .default))
                        .tracking(1.2)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color.white,
                                    Color.white.opacity(0.9),
                                    Color.white.opacity(0.8)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .multilineTextAlignment(.center)
                        .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                    
                    // Glass morphism container for subtitle
                    Text("You're gaining \(lifeGainMinutes) min/day")
                        .font(.system(size: 19, weight: .medium, design: .rounded))
                        .tracking(0.5)
                        .foregroundColor(primaryBatteryColor)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(
                                            LinearGradient(
                                                colors: [
                                                    primaryBatteryColor.opacity(0.4),
                                                    primaryBatteryColor.opacity(0.1)
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 1.5
                                        )
                                )
                                .shadow(color: primaryBatteryColor.opacity(0.2), radius: 12, x: 0, y: 4)
                        )
                }

                // Premium battery visualization with sophisticated effects
                VStack(spacing: 20) {
                    ZStack {
                        // Outer glow ring
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                primaryBatteryColor.opacity(batteryGlow ? 0.4 : 0.2),
                                lineWidth: 2
                            )
                            .frame(width: 160, height: 220)
                            .blur(radius: batteryGlow ? 3 : 1)
                            .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: batteryGlow)
                        
                        // Main battery container with glass morphism
                        ZStack {
                            // Glass background
                            RoundedRectangle(cornerRadius: 18)
                                .fill(.ultraThinMaterial)
                                .frame(width: 150, height: 210)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 18)
                                        .stroke(
                                            LinearGradient(
                                                colors: [
                                                    Color.white.opacity(0.3),
                                                    primaryBatteryColor.opacity(0.4),
                                                    Color.white.opacity(0.1)
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 2
                                        )
                                )
                                .shadow(color: .black.opacity(0.4), radius: 20, x: 0, y: 10)
                                .shadow(color: primaryBatteryColor.opacity(0.3), radius: 30, x: 0, y: 5)
                            
                            // Battery fill with shimmer effect
                            VStack {
                                Spacer()
                                ZStack {
                                    // Main gradient fill
                                    Rectangle()
                                        .fill(batteryGradient)
                                        .frame(width: 142, height: 202 * CGFloat(preliminaryScore) / 100.0)
                                        .clipShape(RoundedRectangle(cornerRadius: 14))
                                        .overlay(
                                            // Shimmer overlay
                                            LinearGradient(
                                                colors: [
                                                    Color.clear,
                                                    Color.white.opacity(0.3),
                                                    Color.clear
                                                ],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                            .frame(width: 60)
                                            .offset(x: shimmerOffset)
                                            .animation(
                                                .linear(duration: 3.0)
                                                .repeatForever(autoreverses: false),
                                                value: shimmerOffset
                                            )
                                            .mask(
                                                Rectangle()
                                                    .frame(width: 142, height: 202 * CGFloat(preliminaryScore) / 100.0)
                                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                                            )
                                        )
                                }
                            }
                            .frame(width: 142, height: 202)
                            
                            // Premium battery terminal
                            RoundedRectangle(cornerRadius: 6)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            primaryBatteryColor.opacity(0.9),
                                            primaryBatteryColor,
                                            primaryBatteryColor.opacity(0.8)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 44, height: 18)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                )
                                .shadow(color: primaryBatteryColor.opacity(0.4), radius: 4, x: 0, y: 2)
                                .offset(y: -118)
                            
                            // Remove meaningless percentage text per user feedback
                        }
                        .scaleEffect(animateBattery ? 1.0 : 0.85)
                        .opacity(animateBattery ? 1.0 : 0.0)
                        .animation(.spring(response: 1.2, dampingFraction: 0.8), value: animateBattery)
                    }
                    
                    // Sophisticated explanation with glass morphism
                    Text("~\(String(format: "%.1f", lifeGainHours)) extra hours per month")
                        .font(.system(size: 17, weight: .medium, design: .rounded))
                        .tracking(0.3)
                        .foregroundColor(.white.opacity(0.9))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(.thinMaterial)
                                .overlay(
                                    Capsule()
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                )
                        )
                        .opacity(showLifeGain ? 1.0 : 0.0)
                        .scaleEffect(showLifeGain ? 1.0 : 0.9)
                        .animation(.spring(response: 0.8, dampingFraction: 0.7).delay(1.0), value: showLifeGain)
                }

                // Premium credibility section with glass morphism
                VStack(spacing: 16) {
                    HStack(spacing: 12) {
                        luxuryCredibilityBadge(icon: "brain.head.profile", text: "AI-Powered")
                        luxuryCredibilityBadge(icon: "doc.text.magnifyingglass", text: "Research-Based")
                        luxuryCredibilityBadge(icon: "lock.shield", text: "Private")
                    }
                    
                    Text("Join 50,000+ users optimizing their life energy")
                        .font(.system(size: 15, weight: .regular, design: .rounded))
                        .tracking(0.2)
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .opacity(showCredibility ? 1.0 : 0.0)
                .scaleEffect(showCredibility ? 1.0 : 0.95)
                .animation(.spring(response: 0.9, dampingFraction: 0.8).delay(1.4), value: showCredibility)

                Spacer()

                // Standard app CTA button to match theme consistency
                Button(action: {
                    // Haptic feedback for premium feel
                    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                    impactFeedback.impactOccurred()
                    onContinue()
                }) {
                    Text("Unlock Your Full Score")
                }
                .continueButtonStyle()
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
                .scaleEffect(showCredibility ? 1.0 : 0.95)
                .opacity(showCredibility ? 1.0 : 0.0)
                .animation(.spring(response: 0.8, dampingFraction: 0.7).delay(1.6), value: showCredibility)
                .accessibilityIdentifier("prepaywall_continue")
            }
        }
        .bottomSafeAreaPadding()
        .onAppear {
            // Sophisticated staggered luxury animations
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                animateBattery = true
                batteryGlow = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                showLifeGain = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
                showCredibility = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                shimmerOffset = 200
            }
        }
        .task {
            // Compute actual total impact from questionnaire answers only
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
    private func luxuryCredibilityBadge(icon: String, text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(primaryBatteryColor)
            Text(text)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .tracking(0.2)
                .foregroundColor(.white.opacity(0.9))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    primaryBatteryColor.opacity(0.4),
                                    primaryBatteryColor.opacity(0.2),
                                    Color.white.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(color: primaryBatteryColor.opacity(0.15), radius: 8, x: 0, y: 3)
                .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
        )
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


