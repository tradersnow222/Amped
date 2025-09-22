import SwiftUI

/// Health access screen that follows Apple Human Interface Guidelines for HealthKit permissions
struct HealthAccessView: View {
    // Action to perform when user taps Continue
    var onContinue: (() -> Void)?
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 12) {
                Text("Health Access")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                
                Text("Allow Amped to access health data to calculate your life battery")
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            .padding(.top, 40)
            
            // Essential health data section
            VStack(alignment: .leading, spacing: 8) {
                Text("Essential Health Data")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .padding(.bottom, 4)
                
                Text("These metrics help calculate your accurate life battery:")
                    .foregroundColor(.secondary)
                    .padding(.bottom, 8)
            }
            .padding(.horizontal, 30)
            .padding(.top, 20)
            
            // Health metrics list with what we need
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    healthMetricRow(
                        icon: "figure.walk",
                        title: "Steps",
                        description: "Your daily activity level powers your movement score"
                    )
                    
                    healthMetricRow(
                        icon: "figure.run",
                        title: "Exercise Minutes",
                        description: "Workout intensity boosts your energy levels"
                    )
                    
                    healthMetricRow(
                        icon: "bed.double.fill",
                        title: "Sleep",
                        description: "Rest quality recharges your daily battery"
                    )
                    
                    healthMetricRow(
                        icon: "heart",
                        title: "Resting Heart Rate",
                        description: "Heart efficiency optimizes your battery life"
                    )
                }
                .padding(.horizontal, 30)
            }
            
            Spacer()
            
            // Security assurance
            Text("Your health data is securely processed on your device and never shared.")
                .font(.footnote)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .padding(.bottom, 10)
            
            // Continue button
            Button(action: {
                onContinue?()
            }) {
                HStack {
                    Image(systemName: "heart")
                        .font(.headline)
                    Text("Continue")
                        .fontWeight(.semibold)
                }
                .frame(minWidth: 220)
                .padding()
                .background(Color.ampedGreen)
                .foregroundColor(.white)
                .cornerRadius(14)
                .shadow(color: Color.black.opacity(0.3), radius: 2, x: 0, y: 1)
            }
            .padding(.bottom, 40)
        }
        .withDeepBackground()
    }
    
    /// Helper to create a consistent health metric row
    private func healthMetricRow(icon: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.ampedGreen)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundColor(.ampedYellow)
                .opacity(0.9)
        }
        .padding(.vertical, 8)
    }
} 