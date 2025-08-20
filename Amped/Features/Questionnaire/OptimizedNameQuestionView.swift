import SwiftUI

/// Optimized Name Question View that completely eliminates keyboard lag
/// This view uses a simplified hierarchy and prevents expensive recalculations
struct OptimizedNameQuestionView: View {
    @ObservedObject var viewModel: QuestionnaireViewModel
    @FocusState private var isTextFieldFocused: Bool
    @Environment(\.adaptiveSpacing) private var spacing
    
    // Local state for immediate responsiveness
    @State private var localUserName: String = ""
    @State private var hasInitialized = false
    @State private var debounceTimer: Timer?
    
    // CRITICAL: Track keyboard visibility to disable gestures
    @State private var isKeyboardVisible = false
    
    var body: some View {
        // CRITICAL FIX: Simple VStack without heavy backgrounds or GeometryReaders
        VStack(spacing: 0) {
            // Question text
            Text("What should we call you?")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.bottom, 10)
                .padding(.horizontal, 24)
                .frame(maxWidth: .infinity)

            // Adaptive spacer
            AdaptiveSpacer(minHeight: 20)
            
            // Text field and continue button
            VStack(spacing: spacing.buttonSpacing) {
                // CRITICAL: Simple TextField without complex modifiers
                TextField("First name", text: $localUserName)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.vertical, 16)
                    .padding(.horizontal, 20)
                    .background(
                        // PERFORMANCE: Simple background without animations
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.15))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.25), lineWidth: 1)
                            )
                    )
                    .focused($isTextFieldFocused)
                    .textInputAutocapitalization(.words)
                    .textContentType(.givenName)
                    .submitLabel(.continue)
                    .disableAutocorrection(true)
                    // CRITICAL: Disable animations during typing
                    .animation(nil, value: localUserName)
                    .onSubmit {
                        syncToViewModel()
                        if canProceedLocally {
                            proceedToNext()
                        }
                    }
                    .onChange(of: localUserName) { newValue in
                        // Debounce sync
                        debounceTimer?.invalidate()
                        debounceTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { _ in
                            syncToViewModel()
                        }
                    }
                
                // Continue button
                Button(action: {
                    proceedToNext()
                }) {
                    Text("Continue")
                }
                .questionnaireButtonStyle(isSelected: false)
                .opacity(canProceedLocally ? 1.0 : 0.6)
                .disabled(!canProceedLocally)
                .hapticFeedback(.light)
            }
            .padding(.horizontal, 24)
            .adaptiveBottomPadding()
        }
        .adaptiveSpacing()
        // CRITICAL: Track keyboard visibility
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
            isKeyboardVisible = true
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            isKeyboardVisible = false
        }
        // CRITICAL: Disable gestures when keyboard is visible
        .allowsHitTesting(!isKeyboardVisible || !isTextFieldFocused)
        .onAppear {
            if !hasInitialized {
                localUserName = viewModel.userName
                hasInitialized = true
            }
        }
        .onDisappear {
            debounceTimer?.invalidate()
            debounceTimer = nil
        }
    }
    
    // Local validation
    private var canProceedLocally: Bool {
        !localUserName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    // Sync to view model
    private func syncToViewModel() {
        if viewModel.userName != localUserName {
            viewModel.userName = localUserName
        }
    }
    
    private func proceedToNext() {
        guard canProceedLocally else { return }
        
        // Dismiss keyboard
        isTextFieldFocused = false
        
        // Sync and cleanup
        syncToViewModel()
        debounceTimer?.invalidate()
        debounceTimer = nil
        
        // Navigate
        viewModel.proceedToNextQuestion()
    }
}
