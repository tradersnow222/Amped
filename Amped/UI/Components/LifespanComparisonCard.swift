import SwiftUI
import OSLog

/// Lifespan comparison card showing how user's lifespan compares to average
/// Based on living every day like the last 24 hours with real calculations
struct LifespanComparisonCard: View {
    let userProfile: UserProfile
    let currentProjection: LifeProjection?
    let dailyImpactMinutes: Double // Real daily impact from last 24 hours
    
    private let logger = Logger(subsystem: "Amped", category: "LifespanComparisonCard")
    
    // MARK: - Computed Properties
    
    private var baselineLifeExpectancy: Double {
        guard userProfile.age != nil else { return 78.0 }
        
        // Use baseline mortality adjuster to get accurate baseline
        let mortalityAdjuster = BaselineMortalityAdjuster()
        return mortalityAdjuster.getBaselineLifeExpectancy(for: userProfile)
    }
    
    private var projectedLifespan: Double {
        guard let projection = currentProjection else { return baselineLifeExpectancy }
        return projection.adjustedLifeExpectancyYears
    }
    
    private var differenceFromAverage: Double {
        projectedLifespan - baselineLifeExpectancy
    }
    
    private var isAboveAverage: Bool {
        differenceFromAverage > 0
    }
    
    private var comparisonText: String {
        let absDifference = abs(differenceFromAverage)
        
        if absDifference < 0.1 {
            return "On track with average"
        } else if isAboveAverage {
            let months = Int(round(absDifference * 12))
            if months > 12 {
                let years = months / 12
                return "+\(years) \(years == 1 ? "year" : "years") above average"
            } else {
                return "+\(months) months above average"
            }
        } else {
            let months = Int(round(absDifference * 12))
            if months > 12 {
                let years = months / 12
                return "\(years) \(years == 1 ? "year" : "years") below average"
            } else {
                return "\(months) months below average"
            }
        }
    }
    
    private var explanationText: String {
        if abs(differenceFromAverage) < 0.1 {
            return "Keep up your current habits"
        } else if isAboveAverage {
            return "Your healthy habits are paying off"
        } else {
            return "Small improvements can add years"
        }
    }
    
    private var impactColor: Color {
        if abs(differenceFromAverage) < 0.1 {
            return .ampedYellow
        } else if isAboveAverage {
            return .ampedGreen
        } else {
            return .ampedRed
        }
    }
    
    private var cardBackgroundColor: Color {
        if abs(differenceFromAverage) < 0.1 {
            return .ampedYellow.opacity(0.1)
        } else if isAboveAverage {
            return .ampedGreen.opacity(0.1)
        } else {
            return .ampedRed.opacity(0.1)
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with icon
            HStack(spacing: 12) {
                Image(systemName: isAboveAverage ? "arrow.up.circle.fill" : (abs(differenceFromAverage) < 0.1 ? "minus.circle.fill" : "arrow.down.circle.fill"))
                    .font(.title2)
                    .foregroundColor(impactColor)
                    .symbolRenderingMode(.hierarchical)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Real-time life expectancy")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white.opacity(0.8))
                    
                    Text("\(Int(projectedLifespan)) years")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                
                Spacer()
            }
            
            // Comparison to average
            VStack(alignment: .leading, spacing: 8) {
                Text(comparisonText)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(impactColor)
                
                Text(explanationText)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.leading)
            }
            
            
        }
        .padding(20)
        .background(cardBackgroundColor)
        .glassBackground(.regular, cornerRadius: 16, withBorder: true)
    }
    
    // MARK: - Sub Views
    
    private var comparisonBarView: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Average")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                
                Spacer()
                
                Text("You")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(impactColor)
            }
            
            GeometryReader { geometry in
                let averagePosition = geometry.size.width * 0.5 // Center for average
                let maxDifference: Double = 10.0 // Max years difference to show on scale
                let userPosition: CGFloat = {
                    if isAboveAverage {
                        let normalizedDifference = min(differenceFromAverage, maxDifference) / maxDifference
                        return averagePosition + (geometry.size.width * 0.4 * CGFloat(normalizedDifference))
                    } else {
                        let normalizedDifference = min(abs(differenceFromAverage), maxDifference) / maxDifference
                        return averagePosition - (geometry.size.width * 0.4 * CGFloat(normalizedDifference))
                    }
                }()
                
                ZStack(alignment: .leading) {
                    // Background bar
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.2))
                        .frame(height: 8)
                    
                    // Average marker (always at baseline position)
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.white.opacity(0.6))
                        .frame(width: 2, height: 12)
                        .offset(x: averagePosition - 1)
                    
                    // User position indicator
                    Circle()
                        .fill(impactColor)
                        .frame(width: 14, height: 14)
                        .offset(x: max(0, min(geometry.size.width - 14, userPosition - 7)))
                }
            }
            .frame(height: 14)
        }
    }
    
}

// MARK: - Preview

struct LifespanComparisonCard_Previews: PreviewProvider {
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
        
        VStack(spacing: 20) {
            // Positive impact example
            LifespanComparisonCard(
                userProfile: userProfile,
                currentProjection: currentProjection,
                dailyImpactMinutes: 45.2
            )
            
            // Negative impact example
            LifespanComparisonCard(
                userProfile: userProfile,
                currentProjection: LifeProjection(
                    id: UUID(),
                    calculationDate: Date(),
                    baselineLifeExpectancyYears: 78.5,
                    adjustedLifeExpectancyYears: 76.1,
                    currentAge: 39.0,
                    confidencePercentage: 0.85,
                    confidenceIntervalYears: 2.0
                ),
                dailyImpactMinutes: -32.8
            )
            
            // Neutral impact example
            LifespanComparisonCard(
                userProfile: userProfile,
                currentProjection: LifeProjection(
                    id: UUID(),
                    calculationDate: Date(),
                    baselineLifeExpectancyYears: 78.5,
                    adjustedLifeExpectancyYears: 78.5,
                    currentAge: 39.0,
                    confidencePercentage: 0.85,
                    confidenceIntervalYears: 2.0
                ),
                dailyImpactMinutes: 0.1
            )
        }
        .padding()
        .withDeepBackground()
    }
}
