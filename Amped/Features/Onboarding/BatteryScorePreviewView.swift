import SwiftUI

/// Simple battery score preview shown after questionnaire completion  
struct BatteryScorePreviewView: View {
    @ObservedObject var viewModel: QuestionnaireViewModel
    let onContinue: () -> Void
    
    // Calculate a basic score based on questionnaire answers
    private var preliminaryScore: Int {
        var score = 50 // Start with baseline
        
        // Adjust based on questionnaire responses
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
            case .occasionally: score += 0
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
        
        // Clamp to 0-100 range
        return max(0, min(100, score))
    }
    
    private var batteryColor: Color {
        switch preliminaryScore {
        case 80...100: return .ampedGreen
        case 60..<80: return .ampedYellow
        case 40..<60: return Color.orange
        case 20..<40: return .ampedRed
        default: return .red
        }
    }
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.black,
                    Color.ampedDark.opacity(0.8)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // Title
                Text("Your Preliminary Score")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                // Battery visualization
                VStack(spacing: 20) {
                    ZStack {
                        // Battery outline
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(batteryColor, lineWidth: 4)
                            .frame(width: 120, height: 180)
                        
                        // Battery fill (animated)
                        VStack {
                            Spacer()
                            Rectangle()
                                .fill(batteryColor)
                                .frame(width: 112, height: 172 * CGFloat(preliminaryScore) / 100.0)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .frame(width: 112, height: 172)
                        
                        // Battery terminal
                        RoundedRectangle(cornerRadius: 3)
                            .fill(batteryColor)
                            .frame(width: 36, height: 12)
                            .offset(y: -102)
                        
                        // Score text overlay
                        Text("\(preliminaryScore)%")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .scaleEffect(1.0)
                    .animation(.easeInOut(duration: 1.0), value: preliminaryScore)
                }
                
                // Subtitle
                Text("Based on your health habits, here's your starting battery level")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                
                // Scientific note
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundColor(.ampedGreen.opacity(0.7))
                        Text("HealthKit data will refine this score")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.ampedGreen.opacity(0.7))
                    }
                    
                    Text("Your complete analysis will include activity, sleep, and heart rate data")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 60)
                }
                
                Spacer()
                
                // Continue button
                Button(action: onContinue) {
                    Text("Continue")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(Color.ampedGreen)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
            }
        }
    }
}

#Preview {
    BatteryScorePreviewView(
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
