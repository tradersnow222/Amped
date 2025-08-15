import SwiftUI
import OSLog

/// Simplified real-time life progress bar showing essential life progress information
/// Clean design inspired by the second screenshot with minimal redundancy
struct RealTimeLifeProgressBar: View {
    @State private var userProfile: UserProfile
    let currentProjection: LifeProjection?
    let potentialProjection: LifeProjection?
    let selectedTab: Int // 0 = Current Lifespan, 1 = Potential Lifespan
    
    private let logger = Logger(subsystem: "Amped", category: "RealTimeLifeProgressBar")
    
    init(userProfile: UserProfile, currentProjection: LifeProjection?, potentialProjection: LifeProjection?, selectedTab: Int) {
        self._userProfile = State(initialValue: userProfile)
        self.currentProjection = currentProjection
        self.potentialProjection = potentialProjection
        self.selectedTab = selectedTab
    }
    
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
        // Only show for Potential Lifespan tab
        guard selectedTab == 1,
              let potentialProj = potentialProjection,
              let currentProj = currentProjection else { return 0.0 }
        
        let additionalYears = potentialProj.adjustedLifeExpectancyYears - currentProj.adjustedLifeExpectancyYears
        let adjustmentPercentage = (additionalYears / potentialProj.adjustedLifeExpectancyYears) * 100
        return max(0.0, min(15.0, adjustmentPercentage)) // Cap at 15% for visual balance
    }
    
    private var lifestyleAdjustmentYears: Double {
        guard selectedTab == 1,
              let potentialProj = potentialProjection,
              let currentProj = currentProjection else { return 0.0 }
        
        return max(0.0, potentialProj.adjustedLifeExpectancyYears - currentProj.adjustedLifeExpectancyYears)
    }
    
    private var lifestyleAdjustmentPercentageText: String {
        guard selectedTab == 1 && lifestyleAdjustmentYears > 0 else { return "" }
        return "+\(String(format: "%.1f", lifestyleAdjustmentPercentage))% from optimal habits"
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
            
            // Lifestyle adjustment text (only for Potential Lifespan)
            if selectedTab == 1 && !lifestyleAdjustmentPercentageText.isEmpty {
                Text(lifestyleAdjustmentPercentageText)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.ampedGreen)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 4)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 20) // Increased padding to make component narrower
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ProfileDataUpdated"))) { _ in
            // Reload user profile when it's updated in settings
            loadUpdatedUserProfile()
        }
    }
    
    private func loadUpdatedUserProfile() {
        // Load updated profile from UserDefaults
        if let data = UserDefaults.standard.data(forKey: "user_profile") {
            do {
                let updatedProfile = try JSONDecoder().decode(UserProfile.self, from: data)
                userProfile = updatedProfile
            } catch {
                // Handle decoding error silently or with proper logging
            }
        }
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
                    
                    // Lifestyle adjustment (green section at the end) - Only for Potential Lifespan
                    if selectedTab == 1 && lifestyleAdjustmentPercentage > 0 {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.ampedGreen)
                            .frame(width: geometry.size.width * (lifestyleAdjustmentPercentage / 100.0), height: 12)
                            .offset(x: geometry.size.width * (1.0 - lifestyleAdjustmentPercentage / 100.0)) // Position at the end
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
