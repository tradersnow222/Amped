import SwiftUI

/// New progress bar style stepper for onboarding with back arrow button
struct ProgressBarStepper: View {
    let currentStep: Int
    let totalSteps: Int
    let onBackTap: (() -> Void)?
    
    init(currentStep: Int, totalSteps: Int, onBackTap: (() -> Void)? = nil) {
        self.currentStep = currentStep
        self.totalSteps = totalSteps
        self.onBackTap = onBackTap
    }
    
    var body: some View {
        HStack(spacing: 24) {
            // Back arrow button - always visible
            Button(action: {
                onBackTap?()
            }) {
                Image(systemName: "arrow.left")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 24, height: 24)
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(red: 0.15, green: 0.15, blue: 0.15, opacity: 1.0)) // #272727
                    )
            }
            .disabled(onBackTap == nil)
            
            // Progress bar
            VStack(spacing: 8) {
                // Progress indicator
                HStack {
                    Text("\(currentStep)/\(totalSteps)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                    Spacer()
                }
                
                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background bar
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.white.opacity(0.2))
                            .frame(height: 4)
                        
                        // Progress fill
                        RoundedRectangle(cornerRadius: 2)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color("ampedGreen"),
                                        Color("ampedYellow")
                                    ]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: max(0, geometry.size.width * progressPercentage), height: 4)
                            .animation(.easeInOut(duration: 0.3), value: progressPercentage)
                    }
                }
                .frame(height: 4)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }
    
    private var progressPercentage: Double {
        guard totalSteps > 0, currentStep >= 0 else { return 0 }
        let percentage = Double(currentStep) / Double(totalSteps)
        return min(max(percentage, 0.0), 1.0) // Clamp between 0 and 1
    }
}

// MARK: - Preview
struct ProgressBarStepper_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            ProgressBarStepper(currentStep: 1, totalSteps: 12)
            ProgressBarStepper(currentStep: 3, totalSteps: 12)
            ProgressBarStepper(currentStep: 6, totalSteps: 12)
            ProgressBarStepper(currentStep: 12, totalSteps: 12)
        }
        .background(Color.black)
        .preferredColorScheme(.dark)
    }
}
