import SwiftUI

/// Initial welcoming screen for the onboarding flow
struct WelcomeView: View {
    @EnvironmentObject var appState: AppState
    // MARK: - Properties
    
    @State private var isAppeared = false
    @State private var glowOpacity: Double = 1.0
    @State private var scale: CGFloat = 1.0
    @State private var showLoader = false
    @State private var progress: CGFloat = 0.0
    @State private var autoAdvanceTask: Task<Void, Never>?
    
    // Use the shared DashboardViewModel injected at the app root
    @EnvironmentObject private var dashboardViewModel: DashboardViewModel
    
    var onContinue: (() -> Void)?
    private let pulseAnimationDuration: Double = 0.8
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            
            // Background Image
            Image("femaleBg")
                .resizable()
                .scaledToFill()
                .opacity(0.40)
                .ignoresSafeArea()
            
            // Gradient Overlay
            LinearGradient.ampBlueGradient
                .ignoresSafeArea()
            
            // MARK: Main Content
            if !showLoader {
                VStack(spacing: 2) {
                    Text("Welcome to")
                        .font(.poppins(18, weight: .regular))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .opacity(isAppeared ? 1 : 0)
                        .offset(y: isAppeared ? 0 : 20)
                        .animation(.easeOut(duration: 0.8), value: isAppeared)
                    
                    HStack {
                        Image("heart")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 40, height: 50)
                            .scaleEffect(scale)
                            .opacity(glowOpacity)
                            .shadow(color: Color.white.opacity(0.6), radius: 10)
                        
                        Text("Amped")
                            .font(.poppins(42, weight: .thin))
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .opacity(isAppeared ? 1 : 0)
                            .offset(y: isAppeared ? 0 : 20)
                            .animation(.easeOut(duration: 0.8).delay(0.2), value: isAppeared)
                    }
                }
            } else {
                // MARK: Circular Loader
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.2), lineWidth: 19)
                        .frame(width: 120, height: 120)
                    
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color(hex: "#18EF47"),
                                    Color(hex: "#00AFAA00").opacity(0.2)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 19, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .frame(width: 120, height: 120)
                        .animation(.easeOut(duration: 1.0), value: progress)

                    
                    Text("\(Int(progress * 100))%")
                        .font(.poppins(22, weight: .medium))
                        .foregroundColor(.white)
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            // Start the shared DashboardViewModel once during the welcome screen
            dashboardViewModel.startIfNeeded()
            startWelcomeSequence()
            checkTrialExpiry()
        }
        .onDisappear {
            autoAdvanceTask?.cancel()
        }
    }
    
    func checkTrialExpiry() {
        guard let start = UserDefaults.standard.object(forKey: "trial_start_date") as? Date else {
            return  // trial never started
        }

        let threeDaysLater = Calendar.current.date(byAdding: .day, value: 3, to: start)!
        let isTrialExpired = Date() >= threeDaysLater
        appState.updateSubscriptionStatus(isTrialExpired)
    }
    
    // MARK: - Welcome Sequence Logic
    
    private func startWelcomeSequence() {
        let orchestrationStartTime = CFAbsoluteTimeGetCurrent()
        print("🚀 PERFORMANCE_ORCHESTRATION: Starting ultra-performance loading during welcome screen")
        
        // Step 1: Fade-in and pulse animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            isAppeared = true
            
            // Start logo pulse animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                withAnimation(.easeInOut(duration: pulseAnimationDuration).repeatCount(5, autoreverses: true)) {
                    glowOpacity = 0.95
                    scale = 1.12
                }
            }
        }
        
        // Step 2: Perform background orchestration during 4s display
        Task.detached(priority: .userInitiated) {
            await performUltraPerformanceOrchestration(startTime: orchestrationStartTime)
        }
        
        // Step 3: After 4 seconds, show circular loader
        autoAdvanceTask = Task {
            try? await Task.sleep(for: .seconds(3.0))
            
            await MainActor.run {
                withAnimation(.easeInOut) {
                    onContinue?()
//                    showLoader = true
                }
//                animateCircularLoader()
            }
        }
    }
    
    // MARK: - Circular Loader Animation
    
    private func animateCircularLoader() {
        progress = 0.0
        
        Timer.scheduledTimer(withTimeInterval: 0.03, repeats: true) { timer in
            progress += 0.01
            
            if progress >= 1.0 {
                timer.invalidate()
                
                // Loader completed → Continue
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation {
                        onContinue?()
                    }
                }
            }
        }
    }
    
    // MARK: - Mock background orchestration (replace with your logic)
    private func performUltraPerformanceOrchestration(startTime: CFAbsoluteTime) async {
        try? await Task.sleep(for: .seconds(3.5))
        let totalTime = CFAbsoluteTimeGetCurrent() - startTime
        print("✅ Orchestration completed in \(totalTime)s — All systems ready")
    }
}

#Preview {
    WelcomeView()
        .environmentObject(DashboardViewModel())
}
