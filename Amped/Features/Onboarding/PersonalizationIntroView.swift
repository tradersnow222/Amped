import SwiftUI

/// Introduction to personalization and questionnaire
struct PersonalizationIntroView: View {
    // MARK: - Properties
    
    @StateObject private var viewModel = PersonalizationIntroViewModel()
    @State private var isAnimating = false
    @State private var nudgeAnimation = false
    @State private var nudgeOffset: CGFloat = 0
    @State private var nudgeTimer: Timer?
    @State private var dragOffset: CGFloat = 0
    
    // Callback to proceed to next step
    var onContinue: (() -> Void)?
    
    // MARK: - UI Constants
    private let nudgeDistance: CGFloat = 20
    
    // MARK: - Body
    
    var body: some View {
        ZStack(alignment: .top) {
            // Background
            Color.clear.withDeepBackground()
            
            // Content with fixed progress indicator at bottom
            VStack(spacing: 0) {
                // Main content - can be nudged
                VStack(spacing: 0) {
                    // Expanded spacer to push content to center
                    Spacer()
                    
                    // Main content - centered in the screen
                    VStack(spacing: 24) {
                        // Headline text - larger and more prominent
                        Text("First, let's go through a few questions")
                            .font(.title2.bold().monospaced())
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                        
                        // Subheadline - increased size for better visibility
                        Text("takes about 2 minutes")
                            .font(.subheadline.monospaced())
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 30)
                    .offset(x: nudgeOffset + dragOffset)
                    
                    Spacer()
                }
                
                // Progress indicator - fixed position
                ProgressIndicator(currentStep: 1, totalSteps: 10)
                    .padding(.bottom, 40)
            }
        }
        .edgesIgnoringSafeArea(.all)
        .navigationBarHidden(true)
        .onAppear {
            // Start nudging animation after 2 seconds (reduced from 3)
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                startNudgeAnimation()
            }
        }
        .onDisappear {
            // Clean up timer when view disappears
            nudgeTimer?.invalidate()
            nudgeTimer = nil
        }
        .gesture(
            DragGesture(minimumDistance: 5, coordinateSpace: .local)
                .onChanged { value in
                    // Only handle horizontal drags
                    if abs(value.translation.width) > abs(value.translation.height) {
                        if value.translation.width < 0 {
                            // Left swipe (proceed) - update offset in real-time
                            dragOffset = value.translation.width
                            
                            // If drag exceeds threshold, proceed immediately
                            if dragOffset < -50 {
                                nudgeTimer?.invalidate()
                                nudgeTimer = nil
                                onContinue?()
                            }
                        }
                    }
                }
                .onEnded { value in
                    // Reset drag offset with animation if we didn't exceed threshold
                    withAnimation(.spring()) {
                        dragOffset = 0
                    }
                    
                    if value.translation.width < -20 {
                        // Left swipe - proceed to next screen
                        nudgeTimer?.invalidate()
                        nudgeTimer = nil
                        onContinue?()
                    }
                }
        )
        .onTapGesture {
            // Tap gesture for easier navigation as well
            nudgeTimer?.invalidate()
            nudgeTimer = nil
            onContinue?()
        }
    }
    
    // MARK: - Helper Methods
    
    private func startNudgeAnimation() {
        // Initial nudge
        performNudge()
        
        // Set up repeating timer with 2 second interval (1s for animation + 1s pause)
        nudgeTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            performNudge()
        }
    }
    
    private func performNudge() {
        // Animate to nudged position (increased to 0.6 seconds)
        withAnimation(.easeInOut(duration: 0.6)) {
            nudgeOffset = -nudgeDistance
        }
        
        // Animate back after nudge completes (0.6 seconds delay with 0.4 seconds duration)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation(.easeInOut(duration: 0.4)) {
                nudgeOffset = 0
            }
        }
    }
}

// MARK: - ViewModel

final class PersonalizationIntroViewModel: ObservableObject {
    @Published var showQuestionnaire = false
    
    func proceedToQuestionnaire() {
        showQuestionnaire = true
    }
}

// MARK: - Preview

struct PersonalizationIntroView_Previews: PreviewProvider {
    static var previews: some View {
        PersonalizationIntroView(onContinue: {})
    }
} 