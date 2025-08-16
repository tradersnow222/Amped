import SwiftUI

/// Introduction to personalization and questionnaire - builds credibility with scientific backing
struct PersonalizationIntroView: View {
    // MARK: - Properties
    
    // PERFORMANCE FIX: Remove unnecessary @StateObject that blocks main thread
    @State private var animateElements = false
    @EnvironmentObject var themeManager: BatteryThemeManager
    
    // Callback to proceed to next step
    var onContinue: (() -> Void)?
    
    // MARK: - Body
    
    var body: some View {
        ZStack(alignment: .top) {
            // Content without background since parent provides static background
            
            VStack(spacing: 0) {
                // Main content
                ScrollView {
                    VStack(spacing: 48) {
                        // Header section - positioned for rule of thirds
                        VStack(spacing: 0) {
                            Text("Driven by Data,\nFueled by AI.")
                                .font(.system(size: 32, weight: .semibold, design: .rounded))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                                .opacity(animateElements ? 1 : 0)
                                .offset(y: animateElements ? 0 : 20)
                                .animation(.easeOut(duration: 0.9), value: animateElements)
                        }
                        .padding(.top, 100)
                        
                        // Statistics section with paired subtitle
                        VStack(spacing: 16) {
                            Text("Our AI lifespan models are based on")
                                .font(.system(size: 18, weight: .regular, design: .rounded))
                                .foregroundColor(.white.opacity(0.7))
                                .multilineTextAlignment(.center)
                                .opacity(animateElements ? 1 : 0)
                                .animation(.easeOut(duration: 0.9).delay(0.15), value: animateElements)
                            
                            VStack(spacing: 8) {
                            HStack(spacing: 8) {
                                Text("200+")
                                    .font(.system(size: 36, weight: .semibold, design: .rounded))
                                    .foregroundColor(.ampedGreen)
                                Text("peer-reviewed studies")
                                    .font(.system(size: 20, weight: .regular, design: .rounded))
                                    .foregroundColor(.white)
                            }
                            
                            Text("with over")
                                .font(.system(size: 16, weight: .regular, design: .rounded))
                                .foregroundColor(.white.opacity(0.7))
                            
                            HStack(spacing: 8) {
                                Text("10 million")
                                    .font(.system(size: 36, weight: .semibold, design: .rounded))
                                    .foregroundColor(.ampedGreen)
                                Text("participants")
                                    .font(.system(size: 20, weight: .regular, design: .rounded))
                                    .foregroundColor(.white)
                            }
                            }
                        }
                        .opacity(animateElements ? 1 : 0)
                        .scaleEffect(animateElements ? 1 : 0.9)
                        .animation(.spring(response: 0.72, dampingFraction: 0.978).delay(0.25), value: animateElements)
                        
                        // Visual element - Battery with scientific symbols
                        scientificBatteryView
                            .padding(.vertical, 20)
                            .opacity(animateElements ? 1 : 0)
                            .scaleEffect(animateElements ? 1 : 0.8)
                            .animation(.spring(response: 0.72, dampingFraction: 0.978).delay(0.3), value: animateElements)
                        
                        // University partnerships
                        VStack(spacing: 24) {
                            Text("With insights from experts at:")
                                .font(.system(size: 16, weight: .regular, design: .rounded))
                                .foregroundColor(.white.opacity(0.7))
                            
                            // University logos in horizontal layout
                            HStack(spacing: 24) {
                                ForEach(ResearchInstitute.allCases, id: \.self) { institute in
                                    universityLogoView(for: institute)
                                }
                            }
                            .fixedSize(horizontal: true, vertical: false) // Prevent horizontal wrapping
                        }
                        .opacity(animateElements ? 1 : 0)
                        .animation(.easeOut(duration: 0.9).delay(0.45), value: animateElements)
                        
                        Spacer(minLength: 48)
                    }
                    .padding(.horizontal, 24)
                }
                
                // Bottom section with button
                VStack(spacing: 0) {
                    Button(action: {
                        onContinue?()
                    }) {
                        Text("Continue")
                            .fontWeight(.bold)
                            .font(.system(.title3, design: .rounded))
                            .frame(maxWidth: .infinity, minHeight: 52)
                            .padding(.vertical, 10)
                            .padding(.horizontal, 16)
                            .background(Color.ampedGreen)
                            .foregroundColor(.white)
                            .cornerRadius(14)
                    }
                    .minTappableArea(52)
                    .hapticFeedback(.medium)
                    .padding(.horizontal, 40)
                    .shadow(color: Color.black.opacity(0.3), radius: 3, x: 0, y: 2)
                    .opacity(animateElements ? 1 : 0)
                    .animation(.easeOut(duration: 0.9).delay(0.55), value: animateElements)
                    
                    // Add spacer to match WelcomeView button position
                    Spacer().frame(height: 120)
                }
            }
        }
        .edgesIgnoringSafeArea(.all)
        .navigationBarHidden(true)
        .onAppear {
            withAnimation {
                animateElements = true
            }
        }
    }
    
    // MARK: - Subviews
    
    private var scientificBatteryView: some View {
        ZStack {
            // Battery outline with scientific elements
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.ampedGreen, lineWidth: 3)
                .frame(width: 120, height: 60)
                .overlay(
                    HStack(spacing: 0) {
                        // DNA helix symbol
                        Image(systemName: "waveform.path.ecg")
                            .font(.system(size: 24))
                            .foregroundColor(.ampedGreen)
                        
                        // Plus sign
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white.opacity(0.7))
                            .padding(.horizontal, 8)
                        
                        // AI brain symbol
                        Image(systemName: "brain")
                            .font(.system(size: 24))
                            .foregroundColor(.ampedGreen)
                    }
                )
            
            // Battery tip
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.ampedGreen)
                .frame(width: 6, height: 30)
                .offset(x: 68)
        }
    }
    
    private func universityLogoView(for institute: ResearchInstitute) -> some View {
        HStack(spacing: 6) {
            // University icon/symbol for NYU
            if institute == .nyu {
                Image(systemName: "building.columns.fill")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
            }
            
            // University name
            Text(institute.rawValue)
                .font(.system(size: 16, weight: .regular, design: .rounded))
                .foregroundColor(.white.opacity(0.8))
                .fixedSize()
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
            .environmentObject(BatteryThemeManager())
    }
}
