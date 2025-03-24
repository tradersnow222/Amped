import SwiftUI

/// Introduction to personalization and questionnaire
struct PersonalizationIntroView: View {
    // MARK: - Properties
    
    @StateObject private var viewModel = PersonalizationIntroViewModel()
    @State private var batteryFill: Double = 0.5
    @State private var isAnimating = false
    
    // MARK: - UI Constants
    
    private let batteryHeight: CGFloat = 100
    private let batteryWidth: CGFloat = 180
    private let swipeIndicatorSize: CGFloat = 40
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 30) {
            // Title
            Text("Power Up Your Experience")
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .padding(.top, 40)
            
            // Battery icon at 50% charge
            batteryVisualization
                .padding(.vertical, 20)
            
            // Benefits description
            VStack(spacing: 24) {
                benefitIcon(icon: "bolt.circle.fill", text: "Custom power analysis")
                benefitIcon(icon: "heart.circle.fill", text: "Personalized health insights")
                benefitIcon(icon: "gauge.circle.fill", text: "Accurate lifespan impact")
            }
            
            Spacer()
            
            // Questionnaire description
            VStack(spacing: 20) {
                Text("Let's go through a few quick questions to customize your battery")
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Text("5-8 questions, takes about 1 minute")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Swipe right gesture animation
            HStack {
                Image(systemName: "arrow.right")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: swipeIndicatorSize, height: swipeIndicatorSize)
                    .background(Color.ampedGreen)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color.ampedGreen.opacity(0.3), lineWidth: 4)
                            .scaleEffect(isAnimating ? 1.5 : 1.0)
                            .opacity(isAnimating ? 0.0 : 1.0)
                    )
                    .offset(x: isAnimating ? 20 : 0)
                    .animation(
                        Animation.easeInOut(duration: 1.5)
                            .repeatForever(autoreverses: false),
                        value: isAnimating
                    )
                    .onAppear {
                        isAnimating = true
                    }
                
                Text("Swipe right to begin")
                    .font(.headline)
                    .foregroundColor(Color.ampedGreen)
                    .padding(.leading, 10)
            }
            .padding(.bottom, 20)
            
            // Progress indicator
            ProgressIndicator(currentStep: 2, totalSteps: 7)
                .padding(.bottom, 40)
        }
        .gesture(
            DragGesture(minimumDistance: 50)
                .onEnded { gesture in
                    if gesture.translation.width > 0 {
                        // Swipe right detected
                        viewModel.proceedToQuestionnaire()
                    }
                }
        )
        .background(Color(.systemBackground))
        .edgesIgnoringSafeArea(.bottom)
        .navigationBarHidden(true)
        .fullScreenCover(isPresented: $viewModel.showQuestionnaire) {
            // This would lead to the first questionnaire screen
            QuestionnaireView()
        }
    }
    
    // MARK: - UI Components
    
    /// Battery visualization at 50% charge
    private var batteryVisualization: some View {
        ZStack {
            // Battery body
            HStack(spacing: 2) {
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.gray, lineWidth: 4)
                    .frame(width: batteryWidth, height: batteryHeight)
                    .overlay(
                        GeometryReader { geometry in
                            RoundedRectangle(cornerRadius: 6)
                                .fill(LinearGradient(
                                    gradient: Gradient(colors: [Color.ampedYellow, Color.ampedGreen]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ))
                                .frame(width: (geometry.size.width - 8) * batteryFill)
                                .padding(4)
                        }
                    )
                
                // Battery terminal
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray)
                    .frame(width: 15, height: 40)
            }
            
            // Battery charge level
            Text("50%")
                .font(.system(.title, design: .rounded))
                .fontWeight(.bold)
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
        }
    }
    
    /// Single benefit icon with text
    private func benefitIcon(icon: String, text: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 32))
                .foregroundColor(Color.ampedGreen)
            
            Text(text)
                .font(.body)
            
            Spacer()
        }
        .padding(.horizontal, 40)
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
        PersonalizationIntroView()
    }
} 