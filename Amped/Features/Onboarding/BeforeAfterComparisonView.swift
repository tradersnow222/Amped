import SwiftUI

/// Before/After comparison screen inspired by BetterSleep's "You today" vs "You in a week" concept
/// Applied rules: Simplicity is KING; single CTA; no unverifiable claims. Matches premium onboarding theme.
struct BeforeAfterComparisonView: View {
    var onContinue: () -> Void

    // Subtle animated fill for a premium feel (kept minimal per Simplicity rule)
    @State private var todayFill: CGFloat = 0.0
    @State private var weekFill: CGFloat = 0.0
    // Delay battery animations until after view transition completes (Simplicity is KING)
    @State private var canAnimateBatteries: Bool = false
    @State private var targetTodayFill: CGFloat = 0.0
    @State private var targetWeekFill: CGFloat = 0.0
    // Shared opacity so batteries "materialize" in sync with fill
    @State private var batteryOpacity: Double = 0.0
    @StateObject private var viewModel = BeforeAfterComparisonViewModel()

    var body: some View {
        ZStack {
            Color.clear.withDeepBackground()

            VStack(spacing: 0) {
                // Premium headline + subheadline to match onboarding typography
                VStack(spacing: 10) {
                    Text("Unlock the power of small habits")
                        .font(.system(size: 34, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .minimumScaleFactor(0.8)
                        .tracking(-0.5)
                        .shadow(color: .black.opacity(0.45), radius: 4, x: 0, y: 1)
                    Text("See your battery improve with a week of better choices.")
                        .font(.system(size: 17, weight: .regular, design: .rounded))
                        .foregroundColor(.white.opacity(0.85))
                        .multilineTextAlignment(.center)
                        .lineSpacing(2)
                        .shadow(color: .black.opacity(0.35), radius: 3, x: 0, y: 1)
                }
                .padding(.horizontal, 28)
                .padding(.top, 60)

                // Position batteries higher on screen
                Spacer(minLength: 28)

                // Comparison cards centered on screen
                HStack(alignment: .center, spacing: 24) {
                    comparisonCard(title: viewModel.currentLabel, fill: todayFill, color: .ampedYellow, opacity: batteryOpacity)
                    VStack {
                        Spacer()
                        Image(systemName: "arrow.right")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(.white.opacity(0.8))
                            .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                            .offset(y: -14) // Align with battery visual center
                        Spacer()
                    }
                    .frame(height: 196) // Match battery frame height
                    comparisonCard(title: viewModel.potentialLabel, fill: weekFill, color: .ampedGreen, opacity: batteryOpacity)
                }
                .padding(.horizontal, 22)
                .offset(y: -120) // Move batteries much higher up

                Spacer(minLength: 40)

                Button(action: onContinue) {
                    Text("Continue")
                }
                .primaryButtonStyle()
                .padding(.horizontal, 40)
                .padding(.bottom, 32)
            }
        }
        .navigationBarHidden(true)
        .task { await viewModel.load() }
        // Capture updates but animate only when allowed
        .onChange(of: viewModel.currentPercent) { newValue in
            targetTodayFill = newValue
            if canAnimateBatteries {
                withAnimation(.easeInOut(duration: 1.0)) { todayFill = newValue }
            }
        }
        .onChange(of: viewModel.potentialPercent) { newValue in
            targetWeekFill = newValue
            if canAnimateBatteries {
                withAnimation(.easeInOut(duration: 1.2).delay(0.1)) { weekFill = newValue }
            }
        }
        // Enable animations shortly after the screen finishes its transition
        .onAppear {
            // Reset fills to start state while screen is transitioning
            canAnimateBatteries = false
            todayFill = 0.0
            weekFill = 0.0
            batteryOpacity = 0.0
            // Matches onboarding spring response (~0.8s) in `OnboardingFlow.navigateTo`
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.85) {
                canAnimateBatteries = true
            }
        }
        // When animations are allowed, animate to the latest targets
        .onChange(of: canAnimateBatteries) { ready in
            guard ready else { return }
            // Materialize and fill together
            withAnimation(.easeInOut(duration: 0.25)) { batteryOpacity = 1.0 }
            withAnimation(.easeInOut(duration: 1.0)) { todayFill = targetTodayFill }
            withAnimation(.easeInOut(duration: 1.0)) { weekFill = targetWeekFill }
        }
    }

    private func comparisonCard(title: String, fill: CGFloat, color: Color, opacity: Double) -> some View {
        VStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.clear)
                    .frame(width: 136, height: 196)
                    .shadow(color: color.opacity(0.30), radius: 16, x: 0, y: 8)
                    .shadow(color: color.opacity(0.18), radius: 24, x: 0, y: 0)

                ZStack(alignment: .bottom) {
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(
                            LinearGradient(
                                colors: [Color.white.opacity(0.65), color.opacity(0.9)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 3
                        )
                        .frame(width: 128, height: 188)
                        .opacity(opacity)

                    RoundedRectangle(cornerRadius: 10)
                        .fill(
                            LinearGradient(
                                colors: [color.opacity(0.9), color],
                                startPoint: .bottom,
                                endPoint: .top
                            )
                        )
                        .frame(width: 120, height: max(0, 180 * fill))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.bottom, 4)
                }
                .opacity(opacity)
                .overlay(alignment: .bottom) {
                    Text("\(Int(fill * 100))%")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.95))
                        .shadow(color: .black.opacity(0.45), radius: 2, x: 0, y: 1)
                        .padding(.bottom, 10)
                        .opacity(opacity)
                }
                .overlay(alignment: .top) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(color)
                        .frame(width: 34, height: 10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(Color.white.opacity(0.6), lineWidth: 0.5)
                        )
                        .offset(y: -5)
                        .opacity(opacity)
                }
            }
            Text(title)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
                .opacity(opacity)
        }
        .frame(maxWidth: .infinity)
    }
}
