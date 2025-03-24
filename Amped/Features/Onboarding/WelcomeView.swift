import SwiftUI

/// Initial welcoming screen for the onboarding flow
struct WelcomeView: View {
    // MARK: - Properties
    
    @StateObject private var viewModel = WelcomeViewModel()
    @State private var isAnimating = false
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // App logo and animation
            VStack(spacing: 20) {
                Image(systemName: "bolt.batteryblock.fill")
                    .font(.system(size: 80))
                    .foregroundColor(AmpedColors.green)
                    .opacity(isAnimating ? 1.0 : 0.6)
                    .scaleEffect(isAnimating ? 1.1 : 1.0)
                    .shadow(color: AmpedColors.green.opacity(0.5), radius: isAnimating ? 10 : 5, x: 0, y: 0)
                    .animation(
                        Animation.easeInOut(duration: 1.5)
                            .repeatForever(autoreverses: true),
                        value: isAnimating
                    )
                    .onAppear {
                        isAnimating = true
                    }
                
                Text("Amped")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                
                Text("Power Up Your Life")
                    .font(.title2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Get started button
            Button(action: {
                viewModel.proceedToNextStep()
            }) {
                Text("Get Started")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(AmpedColors.green)
                    .foregroundColor(.white)
                    .cornerRadius(14)
            }
            .padding(.horizontal, 40)
            
            // Progress indicator for onboarding steps
            ProgressIndicator(currentStep: 1, totalSteps: 7)
                .padding(.top, 20)
        }
        .padding(.vertical, 40)
        .background(Color(.systemBackground))
        .navigationBarHidden(true)
        .fullScreenCover(isPresented: $viewModel.showPersonalizationIntro) {
            PersonalizationIntroView()
        }
    }
}

// MARK: - Progress Indicator

/// Simple progress dots to show onboarding progress
struct ProgressIndicator: View {
    let currentStep: Int
    let totalSteps: Int
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(1...totalSteps, id: \.self) { step in
                Circle()
                    .fill(step <= currentStep ? AmpedColors.green : Color.gray.opacity(0.3))
                    .frame(width: 8, height: 8)
            }
        }
    }
}

// MARK: - ViewModel

final class WelcomeViewModel: ObservableObject {
    @Published var showPersonalizationIntro = false
    
    func proceedToNextStep() {
        showPersonalizationIntro = true
    }
}

// MARK: - Preview

struct WelcomeView_Previews: PreviewProvider {
    static var previews: some View {
        WelcomeView()
            .preferredColorScheme(.light)
        
        WelcomeView()
            .preferredColorScheme(.dark)
    }
} 