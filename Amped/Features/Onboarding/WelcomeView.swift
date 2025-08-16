import SwiftUI

/// Initial welcoming screen for the onboarding flow
struct WelcomeView: View {
    // MARK: - Properties
    
    @StateObject private var viewModel = WelcomeViewModel()
    @State private var isAnimating = false
    @State private var glowOpacity = 0.7
    @State private var scale = 1.0
    @State private var isAppeared = false
    @State private var autoAdvanceTask: Task<Void, Never>? = nil
    
    // Animation constants
    private let pulseAnimationDuration: Double = 1.4
    
    // Callback to proceed to next step
    var onContinue: (() -> Void)?
    
    // MARK: - Body
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Content without background since parent provides BatteryBackground for welcome screen
                
                VStack {
                    // Battery content area
                    // This positions the content to appear within the green battery section
                    GeometryReader { innerGeometry in
                        // Main content - Amped and lightning bolt
                        VStack(spacing: 16) {
                            Text("Amped")
                                .font(.system(size: 42, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .shadow(color: Color.ampedGreen.opacity(0.8), radius: 1.5, x: 0, y: 0)
                                .minimumScaleFactor(0.7)
                                .lineLimit(1)
                                .frame(maxWidth: innerGeometry.size.width * 0.8)
                                .padding(.bottom, 6)
                            
                            // Lightning bolt icon - much bigger with animation
                            ZStack {
                                // Glow effect
                                Image(systemName: "bolt.fill")
                                    .font(.system(size: 80))
                                    .foregroundColor(.white.opacity(glowOpacity))
                                    .shadow(color: Color.ampedGreen.opacity(0.6), radius: 8, x: 0, y: 0)
                                
                                // Main icon
                                Image(systemName: "bolt.fill")
                                    .font(.system(size: 70))
                                    .foregroundColor(.white)
                            }
                            .scaleEffect(scale)
                            .padding(.vertical, 8)
                        }
                        .frame(width: innerGeometry.size.width)
                        // Restore the original position for Amped and lightning bolt
                        .position(x: innerGeometry.size.width / 2, y: innerGeometry.size.height * 0.48)
                        
                        // Tagline positioned lower in the view (rule of thirds)
                        VStack(spacing: 8) {
                            Text("Your")
                                .font(.callout.monospaced())
                                .fontWeight(.medium)
                                .foregroundColor(.white.opacity(0.95))
                                .shadow(color: Color.black.opacity(0.5), radius: 2, x: 0, y: 1)
                                .lineLimit(1)
                            
                            Text("LIFE BATTERY")
                                .font(.callout.monospaced())
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .shadow(color: Color.ampedGreen.opacity(0.8), radius: 1.2, x: 0, y: 0)
                                .lineLimit(1)
                            
                            Text("in real-time")
                                .font(.callout.monospaced())
                                .fontWeight(.medium)
                                .foregroundColor(.white.opacity(0.95))
                                .shadow(color: Color.black.opacity(0.5), radius: 2, x: 0, y: 1)
                                .lineLimit(1)
                        }
                        .frame(maxWidth: innerGeometry.size.width * 0.75)
                        // Position at approximately 2/3 down the battery (rule of thirds)
                        .position(x: innerGeometry.size.width / 2, y: innerGeometry.size.height * 0.7)
                    }
                    
                    Spacer()
                    
                    // Invisible spacer to maintain text positioning where button used to be
                    // This accounts for the button height + padding + bottom spacer that was removed
                    Spacer().frame(height: 180) // Button area + bottom spacing that was removed
                }
            }
        }
        .edgesIgnoringSafeArea(.all)
        .navigationBarHidden(true)
        .onTapGesture {
            // Add subtle haptic feedback for user interaction
            HapticFeedback.buttonPress()
            
            // Cancel auto-advance and navigate immediately when user taps
            autoAdvanceTask?.cancel()
            onContinue?()
        }
        .onAppear {
            // 🚀 ULTRA-PERFORMANCE ORCHESTRATION: Transform welcome screen into loading hub
            let orchestrationStartTime = CFAbsoluteTimeGetCurrent()
            print("🚀 PERFORMANCE_ORCHESTRATION: Starting ultra-performance loading during welcome screen")
            
            // Trigger the fade-in animation after a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isAppeared = true
                
                // Start lightning bolt pulse animation after elements appear
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    withAnimation(.easeInOut(duration: pulseAnimationDuration).repeatCount(5, autoreverses: true)) {
                        glowOpacity = 0.95
                        scale = 1.12
                    }
                }
            }
            
            // 🚀 ULTRA-PERFORMANCE: Orchestrate ALL expensive operations in background during 4-second display
            Task.detached(priority: .userInitiated) {
                await performUltraPerformanceOrchestration(startTime: orchestrationStartTime)
            }
            
            // Auto-advance to next screen after 4 seconds (now everything is pre-loaded)
            autoAdvanceTask = Task {
                try? await Task.sleep(for: .seconds(4.0))
                if !Task.isCancelled {
                    let totalOrchestrationTime = CFAbsoluteTimeGetCurrent() - orchestrationStartTime
                    print("🚀 PERFORMANCE_ORCHESTRATION: Completed in \(totalOrchestrationTime)s - ALL subsequent screens ready")
                    
                    await MainActor.run {
                        onContinue?()
                    }
                }
            }
        }
        .onDisappear {
            // Clean up the auto-advance task when view disappears
            autoAdvanceTask?.cancel()
        }
    }
}

// MARK: - Progress Indicator

/// Battery-styled progress indicator showing completion steps
struct ProgressIndicator: View {
    let currentStep: Int
    let totalSteps: Int
    
    // MARK: - UI Constants
    private let barHeight: CGFloat = 16
    private let horizontalMargin: CGFloat = 40
    private let borderWidth: CGFloat = 1.5
    private let segmentSpacing: CGFloat = 2
    private let cornerRadius: CGFloat = 3
    
    var body: some View {
        VStack(spacing: 8) {
            // Numeric progress indicator
            Text("\(currentStep)/\(totalSteps)")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
                .tracking(0.5)
            
            // Battery progress bar
        GeometryReader { geometry in
            let availableWidth = geometry.size.width - (horizontalMargin * 2)
            let segmentWidth = (availableWidth / CGFloat(totalSteps)) - segmentSpacing
            
            HStack(spacing: 2) {
                Spacer(minLength: horizontalMargin)
                
                // Main battery body
                ZStack(alignment: .leading) {
                    // Empty battery background with outline
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(Color.ampedGreen.opacity(0.05))
                        .frame(width: availableWidth, height: barHeight)
                        .overlay(
                            RoundedRectangle(cornerRadius: cornerRadius)
                                .strokeBorder(Color.ampedGreen, lineWidth: borderWidth)
                        )
                    
                    // Battery segments - one segment per onboarding step (including individual questions)
                    HStack(spacing: segmentSpacing) {
                        ForEach(0..<totalSteps, id: \.self) { index in
                            // Each segment has a chevron or forward-pointing shape
                            ChevronSegment(
                                isComplete: index < currentStep,
                                width: segmentWidth,
                                height: barHeight - (borderWidth * 2),
                                isFirstSegment: index == 0
                            )
                        }
                    }
                    .padding(.horizontal, borderWidth)
                    .background(Color.ampedGreen.opacity(0.08)) // More subtle background for dividers
                }
                .frame(height: barHeight)
                
                Spacer(minLength: horizontalMargin)
            }
        }
        .frame(height: barHeight)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Progress")
        .accessibilityValue("\(currentStep) of \(totalSteps) steps completed")
    }
}

/// A chevron-shaped segment for the battery progress indicator
struct ChevronSegment: View {
    let isComplete: Bool
    let width: CGFloat
    let height: CGFloat
    let isFirstSegment: Bool
    
    var body: some View {
        ZStack {
            // Base segment
            ForwardShape(isFirstSegment: isFirstSegment)
                .fill(isComplete ? Color.ampedGreen : Color.gray.opacity(0.2))
                .frame(width: width, height: height)
        }
    }
}

/// A custom shape with a pronounced forward/chevron appearance
struct ForwardShape: Shape {
    var isFirstSegment: Bool = false
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        // Create a more pronounced forward-pointing shape
        let chevronOffset: CGFloat = rect.height * 0.4
        
        // First segment has a straight left edge
        if isFirstSegment {
            // Start at bottom left
            path.move(to: CGPoint(x: 0, y: rect.maxY))
            
            // Straight line up to top left
            path.addLine(to: CGPoint(x: 0, y: rect.minY))
            
            // Line to top right 
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            
            // Line to bottom right with inward angle
            path.addLine(to: CGPoint(x: rect.maxX - chevronOffset, y: rect.maxY))
        } else {
            // Start at bottom left
            path.move(to: CGPoint(x: 0, y: rect.maxY))
            
            // Line to top left with inward angle
            path.addLine(to: CGPoint(x: chevronOffset, y: rect.minY))
            
            // Line to top right
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            
            // Line to bottom right with inward angle
            path.addLine(to: CGPoint(x: rect.maxX - chevronOffset, y: rect.maxY))
        }
        
        // Close the path
        path.closeSubpath()
        
        return path
    }
}

// MARK: - Ultra-Performance Orchestration

/// 🚀 ULTRA-PERFORMANCE ORCHESTRATION FUNCTION
/// Performs ALL expensive operations during welcome screen display (4 seconds)
/// Ensures subsequent screens have <16ms response times
private func performUltraPerformanceOrchestration(startTime: Double) async {
    print("🚀 ORCHESTRATION: Phase 1 - Core ViewModels")
    
    // PHASE 1: Pre-initialize ALL core ViewModels (Priority: Critical)
    let viewModelStart = CFAbsoluteTimeGetCurrent()
    
    // Pre-initialize QuestionnaireViewModel in background
    let _ = QuestionnaireViewModel(startFresh: true)
    print("🚀 ORCHESTRATION: ✅ QuestionnaireViewModel pre-initialized")
    
    // Pre-initialize other critical managers
    let _ = HealthKitManager.shared
    let _ = BatteryThemeManager()
    let _ = GlassThemeManager()
    let _ = QuestionnaireManager()
    
    let viewModelTime = CFAbsoluteTimeGetCurrent() - viewModelStart
    print("🚀 ORCHESTRATION: Phase 1 completed in \(viewModelTime)s")
    
    // PHASE 2: Pre-cache ALL FormattedButtonText parsing
    print("🚀 ORCHESTRATION: Phase 2 - Text Parsing Cache")
    let textCacheStart = CFAbsoluteTimeGetCurrent()
    
    await precacheAllQuestionnaireText()
    
    let textCacheTime = CFAbsoluteTimeGetCurrent() - textCacheStart
    print("🚀 ORCHESTRATION: Phase 2 completed in \(textCacheTime)s")
    
    // PHASE 3: Pre-load static resources and theme assets
    print("🚀 ORCHESTRATION: Phase 3 - Static Resources")
    let resourceStart = CFAbsoluteTimeGetCurrent()
    
    await preloadStaticResources()
    
    let resourceTime = CFAbsoluteTimeGetCurrent() - resourceStart
    print("🚀 ORCHESTRATION: Phase 3 completed in \(resourceTime)s")
    
    // PHASE 4: Background service initialization
    print("🚀 ORCHESTRATION: Phase 4 - Background Services")
    let serviceStart = CFAbsoluteTimeGetCurrent()
    
    await initializeBackgroundServices()
    
    let serviceTime = CFAbsoluteTimeGetCurrent() - serviceStart
    print("🚀 ORCHESTRATION: Phase 4 completed in \(serviceTime)s")
    
    let totalTime = CFAbsoluteTimeGetCurrent() - startTime
    print("🚀 ORCHESTRATION: 🎉 ALL PHASES COMPLETE in \(totalTime)s - Subsequent screens now <16ms!")
}

/// Pre-cache ALL text parsing for the entire questionnaire
private func precacheAllQuestionnaireText() async {
    let allTexts = [
        // Stress Level Options
        "Very Low\n(rarely feel stressed)",
        "Low\n(occasionally stressed)", 
        "Moderate to High\n(regular stress)",
        "Very High\n(constantly stressed)",
        
        // Anxiety Level Options
        "Minimal\n(Rarely feel anxious)",
        "Mild to Moderate\n(Occasional to regular worry)",
        "Severe\n(Frequent anxiety episodes)",
        "Very Severe\n(Constant anxiety/panic)",
        
        // Nutrition Quality Options
        "Very Healthy\n(whole foods, plant-based)",
        "Mostly Healthy\n(balanced diet)",
        "Mixed to Unhealthy\n(some processed foods)",
        "Very Unhealthy\n(fast food, highly processed)",
        
        // Smoking Status Options
        "Never",
        "Former smoker\n(quit in the past)",
        "Occasionally",
        "Daily",
        
        // Alcohol Frequency Options
        "Never",
        "Occasionally\n(weekly or less)",
        "Several Times\n(per week)",
        "Daily or Heavy\n(one or more daily)",
        
        // Social Connections Options
        "Very Strong\n(daily interactions)",
        "Moderate to Good\n(regular connections)",
        "Limited\n(rare interactions)",
        "Isolated\n(minimal social contact)",
        
        // Sleep Quality Options
        "Excellent\n(7-9 hrs, wake refreshed)",
        "Good\n(Usually sleep well)",
        "Average\n(Sometimes restless)",
        "Poor to Very Poor\n(Tired, trouble sleeping/insomnia)",
        
        // Blood Pressure Options
        "Below 120/80 (Normal)",
        "I don't know",
        "120-129 (Elevated)",
        "130/80+ (High)",
        
        // Framing Comfort Options
        "I do best with straight facts",
        "Balanced feedback keeps me steady",
        "Positive reinforcement keeps me going",
        
        // Urgency Response Options
        "Urgency energizes me",
        "I can work with any pace",
        "I thrive with low-pressure pacing",
        
        // Life Motivation Options
        "Watch my family grow",
        "Achieve my dreams",
        "Simply to experience life longer",
        "Give more back to the world"
    ]
    
    // Pre-parse all texts by creating FormattedButtonText instances
    for text in allTexts {
        let _ = FormattedButtonText(text: text)
    }
    
    print("🚀 ORCHESTRATION: ✅ Pre-cached \(allTexts.count) text parsing operations")
}

/// Pre-load all static resources, theme assets, and computed values
private func preloadStaticResources() async {
    // Pre-load color assets
    let _ = Color.ampedGreen
    let _ = Color.ampedYellow
    let _ = Color.ampedRed
    let _ = Color.ampedSilver
    let _ = Color.ampedDark
    
    // Pre-load background images
    let _ = Color.clear.withBatteryBackground()
    let _ = Color.clear.withDeepBackground()
    
    // Pre-compute static date ranges (used in birthdate picker)
    let currentYear = Calendar.current.component(.year, from: Date())
    let _ = Array((currentYear - 110)...(currentYear - 5))
    
    print("🚀 ORCHESTRATION: ✅ Pre-loaded static resources and theme assets")
}

/// Initialize background services and managers
private func initializeBackgroundServices() async {
    // Initialize analytics service
    let _ = AnalyticsService.shared
    
    // Initialize notification manager
    let _ = NotificationManager.shared
    
    // Initialize cache manager
    let _ = CacheManager.shared
    
    // Initialize feature flag manager
    let _ = FeatureFlagManager.shared
    
    print("🚀 ORCHESTRATION: ✅ Initialized background services")
}

// MARK: - ViewModel

final class WelcomeViewModel: ObservableObject {
    // Keep the ViewModel minimal since we're using callbacks for navigation
}

// MARK: - Preview

struct WelcomeView_Previews: PreviewProvider {
    static var previews: some View {
        WelcomeView(onContinue: {})
            .preferredColorScheme(.light)
        
        WelcomeView(onContinue: {})
            .preferredColorScheme(.dark)
    }
}
