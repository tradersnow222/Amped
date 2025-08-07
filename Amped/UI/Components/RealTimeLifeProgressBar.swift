import SwiftUI
import OSLog

/// Simplified real-time life progress bar showing essential life progress information
/// Clean design inspired by the second screenshot with minimal redundancy
struct RealTimeLifeProgressBar: View {
    let userProfile: UserProfile
    let currentProjection: LifeProjection?
    let potentialProjection: LifeProjection?
    let selectedTab: Int // 0 = Current Lifespan, 1 = Potential Lifespan
    
    private let logger = Logger(subsystem: "Amped", category: "RealTimeLifeProgressBar")
    
    // MARK: - Computed Properties
    
    private var activeProjection: LifeProjection? {
        selectedTab == 0 ? currentProjection : potentialProjection
    }
    
    private var birthYear: String {
        guard let birthYear = userProfile.birthYear else { return "Unknown" }
        return String(birthYear)
    }
    
    private var projectedEndYear: String {
        guard let projection = activeProjection else { return "Unknown" }
        let endYear = (userProfile.birthYear ?? 2000) + Int(projection.adjustedLifeExpectancyYears)
        return String(endYear)
    }
    
    private var lifeProgressPercentage: Double {
        guard let currentAge = userProfile.age,
              let projection = activeProjection else { return 0.0 }
        
        let totalProjectedYears = projection.adjustedLifeExpectancyYears
        let progressPercentage = (Double(currentAge) / totalProjectedYears) * 100
        
        return min(100.0, max(0.0, progressPercentage))
    }
    
    private var lifestyleAdjustmentPercentage: Double {
        // Calculate lifestyle adjustment as percentage of remaining life
        // This represents the green section showing potential gains
        guard let projection = activeProjection,
              let currentAge = userProfile.age else { return 0.0 }
        
        let baselineLife = 78.0 // Standard baseline
        let adjustedLife = projection.adjustedLifeExpectancyYears
        let adjustment = adjustedLife - baselineLife
        
        // Convert adjustment to percentage of total projected life
        let adjustmentPercentage = (adjustment / adjustedLife) * 100
        return max(0.0, min(15.0, adjustmentPercentage)) // Cap at 15% for visual balance
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 12) {
            // Title
            Text("Real-time life progress")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.white.opacity(0.8))
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Top labels: Birth year, percentage, end year
            HStack {
                Text(birthYear)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white.opacity(0.8))
                    .frame(minWidth: 44)
                
                Spacer()
                
                Text("\(String(format: "%.0f", lifeProgressPercentage))%")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.ampedYellow)
                
                Spacer()
                
                Text(projectedEndYear)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white.opacity(0.8))
                    .frame(minWidth: 44)
            }
            
            // Progress bar
            progressBarView
            
            // Bottom legend
            legendView
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 20) // Increased padding to make component narrower
    }
    
    // MARK: - Sub Views
    
    private var progressBarView: some View {
        VStack(spacing: 4) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background track
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.white.opacity(0.2))
                        .frame(height: 12)
                    
                    // Past (blue section)
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.blue)
                        .frame(width: geometry.size.width * (lifeProgressPercentage / 100.0), height: 12)
                    
                    // Lifestyle adjustment (green section at the end)
                    if lifestyleAdjustmentPercentage > 0 {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.ampedGreen)
                            .frame(width: geometry.size.width * (lifestyleAdjustmentPercentage / 100.0), height: 12)
                            .offset(x: geometry.size.width * 0.85) // Position near the end
                    }
                    
                    // Progress indicator dot
                    Circle()
                        .fill(Color.white)
                        .frame(width: 16, height: 16)
                        .offset(x: (geometry.size.width * (lifeProgressPercentage / 100.0)) - 8)
                        .animation(.easeInOut(duration: 0.6), value: lifeProgressPercentage)
                }
            }
            .frame(height: 16)
            
            // Present text under the white dot
            GeometryReader { geometry in
                Text("Present")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.7))
                    .offset(x: (geometry.size.width * (lifeProgressPercentage / 100.0)) - 20)
                    .animation(.easeInOut(duration: 0.6), value: lifeProgressPercentage)
            }
            .frame(height: 12)
        }
    }
    
    private var legendView: some View {
        HStack(spacing: 8) {
            // Born indicator
            HStack(spacing: 3) {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 8, height: 8)
                Text("Born")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
            
            // End of life indicator
            HStack(spacing: 3) {
                Circle()
                    .fill(Color.ampedGreen)
                    .frame(width: 8, height: 8)
                Text("End of life")
                    .font(.caption2)
                    .foregroundColor(.ampedGreen)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - DateFormatter Extension

private extension DateFormatter {
    static let year: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"
        return formatter
    }()
}

// MARK: - Preview

struct RealTimeLifeProgressBar_Previews: PreviewProvider {
    static var previews: some View {
        let userProfile = UserProfile(
            birthYear: 1985,
            gender: .male
        )
        
        let currentProjection = LifeProjection(
            id: UUID(),
            calculationDate: Date(),
            baselineLifeExpectancyYears: 78.5,
            adjustedLifeExpectancyYears: 82.3,
            currentAge: 39.0,
            confidencePercentage: 0.85,
            confidenceIntervalYears: 2.0
        )
        
        let potentialProjection = LifeProjection(
            id: UUID(),
            calculationDate: Date(),
            baselineLifeExpectancyYears: 78.5,
            adjustedLifeExpectancyYears: 85.1,
            currentAge: 39.0,
            confidencePercentage: 0.78,
            confidenceIntervalYears: 2.5
        )
        
        VStack(spacing: 20) {
            RealTimeLifeProgressBar(
                userProfile: userProfile,
                currentProjection: currentProjection,
                potentialProjection: potentialProjection,
                selectedTab: 0
            )
            
            RealTimeLifeProgressBar(
                userProfile: userProfile,
                currentProjection: currentProjection,
                potentialProjection: potentialProjection,
                selectedTab: 1
            )
        }
        .padding()
        .withDeepBackground()
    }
}
