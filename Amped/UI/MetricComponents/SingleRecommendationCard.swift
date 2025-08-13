import SwiftUI

/// A single focused recommendation card that combines contextual information with actionable tips
struct SingleRecommendationCard: View {
    // MARK: - Properties
    
    /// The health metric to show recommendations for
    let metric: HealthMetric
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack(spacing: 8) {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.ampedYellow)
                    .font(.body)
                
                Text("Recommendation")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
            }
            
            // Main recommendation text
            Text(getRecommendationText())
                .font(.body)
                .foregroundColor(.white.opacity(0.85))
                .fixedSize(horizontal: false, vertical: true)
            
            // Quick action if available
            if let action = getQuickAction() {
                Divider()
                    .background(Color.white.opacity(0.2))
                
                HStack(spacing: 8) {
                    Image(systemName: "bolt.fill")
                        .foregroundColor(.ampedGreen)
                        .font(.body)
                    
                    Text("Try this: \(action)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white.opacity(0.9))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.secondary.opacity(0.2), lineWidth: 1)
        )
    }
    
    // MARK: - Helper Methods
    
    /// Get the main recommendation text for the metric
    private func getRecommendationText() -> String {
        guard let impact = metric.impactDetails else {
            return getDefaultRecommendation()
        }
        
        let isPositive = impact.lifespanImpactMinutes >= 0
        
        switch metric.type {
        case .steps:
            if isPositive {
                return "Great job staying active! Your step count is helping boost your energy levels and heart health. Keep moving throughout the day to maintain this positive impact."
            } else {
                return "Your step count could use a boost. Walking more helps your heart work better, gives you more energy, and can add valuable time to your life. Even small increases make a difference."
            }
            
        case .sleepHours:
            if isPositive {
                return "Your sleep is supporting your health well! Good sleep helps your body recover, keeps your mind sharp, and gives you energy for the day ahead."
            } else {
                return "Getting more quality sleep could significantly improve your health. Sleep is when your body repairs itself and your brain processes the day. Aim for 7-9 hours of consistent sleep."
            }
            
        case .exerciseMinutes:
            if isPositive {
                return "Excellent work with your exercise routine! Regular movement strengthens your heart, improves your mood, and helps your body work at its best."
            } else {
                return "Adding more movement to your day can have powerful health benefits. Exercise doesn't have to be intense - even \(Double(10).formattedAsTime()) to \(Double(15).formattedAsTime()) of walking can help strengthen your heart and boost your energy."
            }
            
        case .restingHeartRate:
            if isPositive {
                return "Your resting heart rate shows good cardiovascular fitness. A lower resting heart rate means your heart is working efficiently, which is great for your long-term health."
            } else {
                return "Your resting heart rate suggests there's room to improve your cardiovascular fitness. Regular cardio exercise like walking, swimming, or cycling can help train your heart to work more efficiently."
            }
            
        case .heartRateVariability:
            if isPositive {
                return "Your heart rate variability indicates good recovery and stress management. This suggests your body is handling daily stresses well and recovering properly."
            } else {
                return "Your heart rate variability suggests your body might be under stress or not recovering well. Focus on good sleep, stress management, and gentle exercise to help improve your recovery."
            }
            
        case .bodyMass:
            if isPositive {
                return "Your weight is in a healthy range that supports your overall well-being. Maintaining this weight through balanced eating and regular activity will continue to benefit your health."
            } else {
                return "Reaching a healthier weight can significantly improve your energy levels and reduce health risks. Focus on eating more whole foods and staying active throughout the day."
            }
            
        case .activeEnergyBurned:
            if isPositive {
                return "You're burning good energy through activity! This shows you're giving your body the movement it needs to stay healthy and strong."
            } else {
                return "Increasing your daily activity can boost your energy levels and health. Look for simple ways to move more - take the stairs, park further away, or take short walking breaks."
            }
            
        case .vo2Max:
            if isPositive {
                return "Your cardiovascular fitness is strong! This means your heart, lungs, and muscles work well together, which is excellent for your long-term health and energy."
            } else {
                return "Improving your cardiovascular fitness can significantly boost your health and energy. Start with activities you enjoy - walking, swimming, or dancing all help build fitness gradually."
            }
            
        case .oxygenSaturation:
            if isPositive {
                return "Your oxygen levels look healthy, which means your body is getting the oxygen it needs to function well."
            } else {
                return "If your oxygen levels are consistently low, consider talking to a healthcare provider. In the meantime, deep breathing exercises and staying active can help."
            }
            
        case .nutritionQuality:
            if isPositive {
                return "Your nutrition choices are supporting your health well! Eating quality foods gives your body the fuel it needs to work at its best."
            } else {
                return "Improving your nutrition can have a huge impact on how you feel and your long-term health. Focus on adding more fruits, vegetables, and whole foods to your meals."
            }
            
        case .smokingStatus:
            if isPositive {
                return "Great job avoiding smoking! This is one of the best things you can do for your health - it helps your lungs, heart, and overall well-being."
            } else {
                return "Quitting smoking is one of the most powerful steps you can take for your health. Your body starts healing within hours of quitting, and the benefits continue to grow over time."
            }
            
        case .alcoholConsumption:
            if isPositive {
                return "Your alcohol consumption is at a level that supports your health. Keeping alcohol intake low helps your liver, sleep, and overall well-being."
            } else {
                return "Reducing alcohol intake can improve your sleep quality, energy levels, and long-term health. Even small reductions can make a meaningful difference."
            }
            
        case .socialConnectionsQuality:
            if isPositive {
                return "Your social connections are supporting your health beautifully! Strong relationships act like medicine for both your mind and body."
            } else {
                return "Building stronger social connections can significantly improve your health and happiness. Reach out to friends, family, or consider joining groups that interest you."
            }
            
        case .stressLevel:
            if isPositive {
                return "You're managing stress well! Lower stress levels help your body focus on healing and keeping you healthy."
            } else {
                return "Managing stress better can have a powerful impact on your health. Try simple techniques like deep breathing, short walks, or talking to someone you trust."
            }
            
        case .bloodPressure:
            if isPositive {
                return "Your blood pressure is in a healthy range! This is excellent for your heart and circulation. Keep up the good habits that are supporting this."
            } else {
                return "Improving your blood pressure can significantly reduce your risk of heart disease and stroke. Focus on regular movement, stress management, and a heart-healthy diet."
            }
        }
    }
    
    /// Get a quick actionable step for the metric
    private func getQuickAction() -> String? {
        switch metric.type {
        case .steps:
            return "Take a 5-minute walk around your home or office"
        case .sleepHours:
            return "Set a bedtime alarm \(Double(30).formattedAsTime()) before you want to sleep"
        case .exerciseMinutes:
            return "Do 10 jumping jacks or pushups right now"
        case .restingHeartRate, .heartRateVariability:
            return "Try 5 deep breaths in through your nose, out through your mouth"
        case .bodyMass:
            return "Drink a glass of water and eat a piece of fruit"
        case .activeEnergyBurned:
            return "Stand up and stretch for \(Double(2).formattedAsTime())"
        case .vo2Max:
            return "Climb a flight of stairs or do 30 seconds of marching in place"
        case .nutritionQuality:
            return "Add a serving of vegetables to your next meal"
        case .smokingStatus:
            return "When you feel an urge, try 10 deep breaths instead"
        case .alcoholConsumption:
            return "Replace one alcoholic drink with sparkling water and lime"
        case .socialConnectionsQuality:
            return "Send a text to someone you care about"
        case .stressLevel:
            return "Take 3 slow, deep breaths and notice how your body feels"
        case .oxygenSaturation:
            return nil // Medical metric - no quick action appropriate
        case .bloodPressure:
            return "Take 5 minutes for slow, deep breathing to help relax your circulation"
        }
    }
    
    /// Get a default recommendation when impact data is unavailable
    private func getDefaultRecommendation() -> String {
        switch metric.type {
        case .steps:
            return "Walking more steps helps your heart stay strong and gives you more energy throughout the day."
        case .sleepHours:
            return "Getting good sleep helps your body recover and keeps your mind sharp."
        case .exerciseMinutes:
            return "Regular exercise strengthens your heart and helps you feel better overall."
        case .restingHeartRate:
            return "A lower resting heart rate usually means your heart is working efficiently."
        case .heartRateVariability:
            return "Good heart rate variability shows your body handles stress well."
        case .bodyMass:
            return "Maintaining a healthy weight supports your overall well-being."
        case .activeEnergyBurned:
            return "Staying active throughout the day helps keep your body healthy and strong."
        case .vo2Max:
            return "Good cardiovascular fitness helps your heart, lungs, and muscles work together well."
        case .oxygenSaturation:
            return "Healthy oxygen levels mean your body is getting what it needs to function well."
        case .nutritionQuality:
            return "Eating quality foods gives your body the nutrients it needs to work at its best."
        case .smokingStatus:
            return "Not smoking is one of the best things you can do for your long-term health."
        case .alcoholConsumption:
            return "Limiting alcohol helps your liver, sleep, and overall health."
        case .socialConnectionsQuality:
            return "Strong relationships are like medicine for both your mind and body."
        case .stressLevel:
            return "Managing stress helps your body focus on healing and staying healthy."
        case .bloodPressure:
            return "Healthy blood pressure keeps your heart and circulation working efficiently."
        }
    }
} 