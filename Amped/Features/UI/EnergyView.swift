import SwiftUI
import Combine

/// Energy View - Shows battery-themed energy and activity tracking
struct EnergyView: View {
    // MARK: - Dependencies
    @StateObject private var viewModel = DashboardViewModel()
    
    // MARK: - State Variables
    @State private var selectedLifespanType: LifespanType = .current
    @State private var showingSettings = false
    @State private var currentTime = Date()
    @State private var animatedYears: Int = 0
    @State private var hasAnimated = false
    
    // Navigation callback
    let onNavigateToProfile: (() -> Void)?
    
    init(onNavigateToProfile: (() -> Void)? = nil) {
        self.onNavigateToProfile = onNavigateToProfile
    }
    
    // Timer for real-time countdown updates
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    // MARK: - Computed Properties (Dynamic from Scientific Calculations)
    private var currentLifespanData: LifespanData {
        guard let lifeProjection = viewModel.lifeProjection else {
            // Fallback while data loads
            return LifespanData(
                years: 0, days: 0, hours: 0, minutes: 0, seconds: 0,
                progress: 0.0, birthYear: 1991, endYear: 2024
            )
        }
        
        // Calculate remaining time based on real projection and current time
        let currentAge = viewModel.currentUserAge
        let totalLifespanYears = lifeProjection.adjustedLifeExpectancyYears
        
        // Calculate exact birth date based on current age
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: currentTime)
        let birthYear = viewModel.userProfile.birthYear ?? (currentYear - Int(currentAge))
        let birthDate = calendar.date(from: DateComponents(year: birthYear, month: 1, day: 1)) ?? currentTime
        
        // Calculate projected end date
        let endDate = calendar.date(byAdding: .year, value: Int(totalLifespanYears), to: birthDate) ?? currentTime
        
        // Calculate real-time remaining time
        let timeInterval = endDate.timeIntervalSince(currentTime)
        let remainingSeconds = max(0, timeInterval)
        
        let years = Int(remainingSeconds / (365.25 * 24 * 60 * 60))
        let days = Int((remainingSeconds.truncatingRemainder(dividingBy: 365.25 * 24 * 60 * 60)) / (24 * 60 * 60))
        let hours = Int((remainingSeconds.truncatingRemainder(dividingBy: 24 * 60 * 60)) / (60 * 60))
        let minutes = Int((remainingSeconds.truncatingRemainder(dividingBy: 60 * 60)) / 60)
        let seconds = Int(remainingSeconds.truncatingRemainder(dividingBy: 60))
        
        // Calculate progress through life
        let progress = currentAge / lifeProjection.adjustedLifeExpectancyYears
        
        // Calculate end year from projected end date
        let endYear = calendar.component(.year, from: endDate)
        
        return LifespanData(
            years: years,
            days: days,
            hours: hours,
            minutes: minutes,
            seconds: seconds,
            progress: progress,
            birthYear: birthYear,
            endYear: endYear
        )
    }
    
    private var potentialLifespanData: LifespanData {
        guard let optimalProjection = viewModel.optimalHabitsProjection,
              let currentProjection = viewModel.lifeProjection else {
            // Fallback while data loads
            return LifespanData(
                years: 0, days: 0, hours: 0, minutes: 0, seconds: 0,
                progress: 0.0, birthYear: 1991, endYear: 2024
            )
        }
        
        // Calculate potential lifespan with optimal habits and real-time countdown
        let currentAge = viewModel.currentUserAge
        let totalOptimalLifespanYears = optimalProjection.adjustedLifeExpectancyYears
        
        // Calculate exact birth date and optimal end date
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: currentTime)
        let birthYear = viewModel.userProfile.birthYear ?? (currentYear - Int(currentAge))
        let birthDate = calendar.date(from: DateComponents(year: birthYear, month: 1, day: 1)) ?? currentTime
        
        // Calculate projected optimal end date
        let optimalEndDate = calendar.date(byAdding: .year, value: Int(totalOptimalLifespanYears), to: birthDate) ?? currentTime
        
        // Calculate real-time remaining time to optimal end
        let timeInterval = optimalEndDate.timeIntervalSince(currentTime)
        let remainingSeconds = max(0, timeInterval)
        
        let years = Int(remainingSeconds / (365.25 * 24 * 60 * 60))
        let days = Int((remainingSeconds.truncatingRemainder(dividingBy: 365.25 * 24 * 60 * 60)) / (24 * 60 * 60))
        let hours = Int((remainingSeconds.truncatingRemainder(dividingBy: 24 * 60 * 60)) / (60 * 60))
        let minutes = Int((remainingSeconds.truncatingRemainder(dividingBy: 60 * 60)) / 60)
        let seconds = Int(remainingSeconds.truncatingRemainder(dividingBy: 60))
        
        // Calculate progress with potential improvements
        let progress = currentAge / optimalProjection.adjustedLifeExpectancyYears
        
        // Calculate extra years gained from optimal habits (rounded for consistency)
        let currentRemainingYears = currentProjection.adjustedLifeExpectancyYears - currentAge
        let optimalRemainingYears = optimalProjection.adjustedLifeExpectancyYears - currentAge
        let extraYears = Double(Int(optimalRemainingYears)) - Double(Int(currentRemainingYears))
        
        // Calculate end year from optimal end date
        let endYear = calendar.component(.year, from: optimalEndDate)
        
        return LifespanData(
            years: years,
            days: days,
            hours: hours,
            minutes: minutes,
            seconds: seconds,
            progress: progress,
            birthYear: birthYear,
            endYear: endYear,
            extraYears: extraYears
        )
    }
    
    private var currentData: LifespanData {
        selectedLifespanType == .current ? currentLifespanData : potentialLifespanData
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            Spacer()
                .frame(height: 0)
            personalizedHeader
            Spacer()
                .frame(height: 14)
            // Lifespan Toggle
            lifespanToggle
            
            // Main Content
//            ScrollView {
                VStack(spacing: 24) {
                    // Call to Action Section
                    callToActionSection
                        .padding(.horizontal, 20)
                    Spacer()
                        .frame(height: 20)
                    // Lifespan Display
                    lifespanDisplaySection
                        .padding(.horizontal, 20)
                    Spacer()
                        .frame(height: 20)
                    // Progress Bar Section
                    progressBarSection
                        .padding(.horizontal, 20)
                    
                    // Disclaimer
                    disclaimerSection
                        .padding(.horizontal, 20)
                }
                .padding(.top, 20)
            }
            
            Spacer() // Space for bottom navigation
//        }
        .onAppear {
            // Load real health data and calculations
            print("🔍 📊 EnergyView: Loading real health data and scientific calculations")
            print("🔍 📊 EnergyView: Current years before load: \(currentData.years)")
            print("🔍 📊 EnergyView: Life projection before load: \(viewModel.lifeProjection?.adjustedLifeExpectancyYears ?? 0)")
            
            viewModel.loadData()
            
            // Start animation after a longer delay to ensure data is fully loaded
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                print("🔍 📊 EnergyView: After 1s delay - Current years: \(currentData.years)")
                print("🔍 📊 EnergyView: After 1s delay - Life projection: \(viewModel.lifeProjection?.adjustedLifeExpectancyYears ?? 0)")
                animateYearsCountdown()
            }
        }
        .onReceive(timer) { time in
            // Update current time every second for real-time countdown
            currentTime = time
        }
        .onChange(of: selectedLifespanType) { _ in
            // Reset animation state when switching tabs so it can animate again
            hasAnimated = false
            animateYearsCountdown()
        }
        .onChange(of: currentData.years) { newValue in
            // Always animate when years value changes and we have a meaningful value
            if newValue > 0 && !hasAnimated {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    animateYearsCountdown()
                }
            }
        }
        .onChange(of: viewModel.lifeProjection) { newProjection in
            // Animate when life projection data becomes available
            print("🔍 📊 LifeProjection changed: \(newProjection?.adjustedLifeExpectancyYears ?? 0)")
            if currentData.years > 0 && !hasAnimated {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    animateYearsCountdown()
                }
            }
        }
        .onChange(of: viewModel.currentUserAge) { newAge in
            // Animate when user age becomes available (indicates data is loaded)
            print("🔍 📊 UserAge changed: \(newAge)")
            if currentData.years > 0 && !hasAnimated {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    animateYearsCountdown()
                }
            }
        }
//        .background(Color.black)
//        .navigationBarHidden(true)
    }
    
    // MARK: - Animation Functions
    
    /// Animate the years countdown from 0 to the target value
    private func animateYearsCountdown() {
        let targetYears = currentData.years
        
        print("🔍 📊 Animation: Starting animation with targetYears: \(targetYears)")
        print("🔍 📊 Animation: Life projection available: \(viewModel.lifeProjection != nil)")
        print("🔍 📊 Animation: Current user age: \(viewModel.currentUserAge)")
        
        // Don't animate if we don't have meaningful data
        guard targetYears > 0 else {
            print("🔍 📊 Animation: No meaningful data to animate, targetYears: \(targetYears)")
            return
        }
        
        // Reset animation state
        animatedYears = 0
        hasAnimated = false
        
        // Calculate animation parameters
        let duration = min(3.0, max(1.5, Double(targetYears) * 0.03)) // Faster animation
        let totalSteps = targetYears
        let stepInterval = duration / Double(max(totalSteps, 1))
        
        print("🔍 📊 Animation: Duration: \(duration), Steps: \(totalSteps), Interval: \(stepInterval)")
        
        // Create a timer-based counter animation
        var currentStep = 0
        let timer = Timer.scheduledTimer(withTimeInterval: stepInterval, repeats: true) { timer in
            currentStep += 1
            
            if currentStep >= totalSteps {
                // Animation complete
                animatedYears = targetYears
                timer.invalidate()
                hasAnimated = true
                print("🔍 📊 Animation: Animation complete, final value: \(targetYears)")
            } else {
                // Update counter
                animatedYears = currentStep
                print("🔍 📊 Animation: Step \(currentStep) of \(totalSteps)")
            }
        }
    }
    
    // MARK: - Header Components
    
    private var personalizedHeader: some View {
        ProfileImageView(
            size: 44, 
            showBorder: false, 
            showEditIndicator: false, 
            showWelcomeMessage: true, 
            userProfile: viewModel.userProfile,
            onTap: {
                // Navigate to Profile tab via callback from parent DashboardView
                onNavigateToProfile?()
            }
        )
    }
    
    private var lifespanToggle: some View {
        HStack(spacing: 4) {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    selectedLifespanType = .current
                }
            }) {
                Text("Current Lifespan")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(selectedLifespanType == .current ? .white : .white.opacity(0.6))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 100)
                            .fill(selectedLifespanType == .current ? Color.black : Color.clear)
                    )
            }
            
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    selectedLifespanType = .potential
                }
            }) {
                Text("Potential Lifespan")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(selectedLifespanType == .potential ? .white : .white.opacity(0.6))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 100)
                            .fill(selectedLifespanType == .potential ? 
                                AnyShapeStyle(LinearGradient(
                                    colors: [.green,.green, .yellow],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )) : AnyShapeStyle(Color.clear)
                            )
                    )
            }
        }
        .padding(.horizontal, 2)
        .padding(.vertical, 2)
        .background(
            RoundedRectangle(cornerRadius: 100)
                .fill(Color(red: 39/255, green: 39/255, blue: 39/255))
        )
        .padding(.horizontal, 24)
//        .padding(.bottom, 20)
    }
    
    // MARK: - Main Content Sections
    
    private var callToActionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.green, .yellow],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 24, height: 24)
                    
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)
                }
                
                Text(selectedLifespanType == .current ? "Real-time life progress" : "Better habits. More Life!")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
            }
            
            Text(selectedLifespanType == .current ? 
                 "This is your current lifespan based on current lifestyle choices." :
                 "With improved habits, extend your lifespan.")
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.leading)
        }
    }
    
    private var lifespanDisplaySection: some View {
        VStack(spacing: 16) {
            // Main years display
            HStack(alignment: .bottom, spacing: 8) {
                Text("\(animatedYears)")
                    .font(.system(size: 64, weight: .bold))
                    .foregroundColor(selectedLifespanType == .current ? .yellow : .green)
                
                Text("years")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.bottom, 8)
            }
            
            // Countdown boxes
            HStack(spacing: 12) {
                CountdownBox(value: "\(currentData.days)", label: "days")
                CountdownBox(value: String(format: "%02d", currentData.hours), label: "hours")
                CountdownBox(value: String(format: "%02d", currentData.minutes), label: "minutes")
                CountdownBox(value: String(format: "%02d", currentData.seconds), label: "seconds")
            }
            
            // Extra years indicator for potential
            if selectedLifespanType == .potential, let extraYears = currentData.extraYears {
                Text("\(String(format: "%.1f", extraYears)) extra years")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.green)
                    .padding(.top, 8)
            }
        }
    }
    
    private var progressBarSection: some View {
        VStack(spacing: 12) {
            // Progress percentage
            HStack {
                Text("Current-\(Int(currentData.progress * 100))%")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.green)
                
                Spacer()
            }
            
            // Progress bar with years inside
            GeometryReader { geometry in
                ZStack {
                    // Background
                    RoundedRectangle(cornerRadius: 100)
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 30)
                    
                    // Progress fill
                    HStack {
                        RoundedRectangle(cornerRadius: 100)
                            .fill(
                                LinearGradient(
                                    colors: [.green,.green, .yellow],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: geometry.size.width * currentData.progress, height: 30)
                        
                        Spacer()
                    }
                    // Years inside progress bar
                    HStack {
                        Text("\(currentData.birthYear)")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Text("\(currentData.endYear)")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 12)
                }
            }
            .frame(height: 16)
            
            // Born and End of Life labels below progress bar
            HStack {
                Text("Born")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.white.opacity(0.6))
                
                Spacer()
                
                Text("Projected lifespan*")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.white.opacity(0.6))
            }.padding(.top,6)
                .padding(.horizontal,6)
        }
    }
    
    private var disclaimerSection: some View {
        VStack(spacing: 8) {
            Text("*Based on 45+ peer-reviewed studies from ")
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.center)
            
            Text("Harvard, AHA, & Mayo Clinic")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.yellow)
        }
//        .padding(.top, 20)
    }
}

// MARK: - Supporting Views

struct CountdownBox: View {
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
            
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(red: 39/255, green: 39/255, blue: 39/255))
        )
    }
}

// MARK: - Data Models

enum LifespanType {
    case current
    case potential
}

struct LifespanData {
    let years: Int
    let days: Int
    let hours: Int
    let minutes: Int
    let seconds: Int
    let progress: Double
    let birthYear: Int
    let endYear: Int
    let extraYears: Double?
    
    init(years: Int, days: Int, hours: Int, minutes: Int, seconds: Int, 
         progress: Double, birthYear: Int, endYear: Int, extraYears: Double? = nil) {
        self.years = years
        self.days = days
        self.hours = hours
        self.minutes = minutes
        self.seconds = seconds
        self.progress = progress
        self.birthYear = birthYear
        self.endYear = endYear
        self.extraYears = extraYears
    }
}

// MARK: - Preview

struct EnergyView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            EnergyView()
        }
        .preferredColorScheme(.dark)
    }
}
