// Test scaling calculations

let dailyImpact = -96.0  // -1.6 hours = -96 minutes (from screenshot)

// Current diminishing returns logic
func currentScaling(_ dailyImpact: Double, days: Double) -> Double {
    let diminishingFactor = days <= 30 ? 0.85 : 0.65
    return dailyImpact * days * diminishingFactor
}

// Test current implementation
let monthlyOld = currentScaling(dailyImpact, days: 30)
let yearlyOld = currentScaling(dailyImpact, days: 365)

print("Current implementation:")
print("Daily: \(dailyImpact) minutes")
print("Monthly: \(monthlyOld) minutes (\(monthlyOld/60) hours)")
print("Yearly: \(yearlyOld) minutes (\(yearlyOld/60) hours)")

// Correct implementation
func correctScaling(_ dailyImpact: Double, days: Double) -> Double {
    // For monthly: use slightly diminished scaling (85%)
    // For yearly: use more diminished scaling (65%)
    let scalingFactor = days <= 30 ? 0.85 : 0.65
    return dailyImpact * days * scalingFactor
}

let monthlyNew = correctScaling(dailyImpact, days: 30)
let yearlyNew = correctScaling(dailyImpact, days: 365)

print("\nShould be:")
print("Daily: \(dailyImpact) minutes")
print("Monthly: \(monthlyNew) minutes (\(monthlyNew/60) hours)")
print("Yearly: \(yearlyNew) minutes (\(yearlyNew/60) hours)")
