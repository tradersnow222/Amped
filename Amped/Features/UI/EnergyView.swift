import SwiftUI
import Combine

/// Energy View - Shows battery-themed energy and activity tracking
struct EnergyView: View {
    // MARK: - State Variables
    @State private var selectedLifespanType: LifespanType = .current
    @State private var showingSettings = false
    var onTapUnlock: (() -> Void)?
    
    // MARK: - Computed Properties
    private var currentLifespanData: LifespanData {
        LifespanData(
            years: 37,
            days: 207,
            hours: 8,
            minutes: 45,
            seconds: 32,
            progress: 0.53,
            birthYear: 1991,
            endYear: 2051
        )
    }
    
    private var potentialLifespanData: LifespanData {
        LifespanData(
            years: 39,
            days: 314,
            hours: 3,
            minutes: 35,
            seconds: 58,
            progress: 0.40,
            birthYear: 1991,
            endYear: 2053,
            extraYears: 2.1
        )
    }
    
    private var currentData: LifespanData {
        selectedLifespanType == .current ? currentLifespanData : potentialLifespanData
    }
    
    var body: some View {
        
        let isPremium = UserDefaults.standard.bool(forKey: "is_premium_user")
        if !isPremium && selectedLifespanType == .potential {
            UnlockSubscriptionView(buttonText: "Unlock Your Best Life by subcribing") {
                // Got to subscription
                onTapUnlock?()
            }
        } else {
            VStack(spacing: 0) {
                // Header
                personalizedHeader
                Spacer()
                // Lifespan Toggle
                lifespanToggle
                
                // Main Content
                ScrollView {
                    VStack(spacing: 24) {
                        // Call to Action Section
                        callToActionSection
                            .padding(.horizontal, 20)
                        Spacer()
                        // Lifespan Display
                        lifespanDisplaySection
                            .padding(.horizontal, 20)
                        Spacer()
                        // Progress Bar Section
                        progressBarSection
                            .padding(.horizontal, 20)
                        
                        // Disclaimer
                        disclaimerSection
                            .padding(.horizontal, 20)
                    }
                    .padding(.top, 20)
                }
                
                Spacer(minLength: 100) // Space for bottom navigation
            }
            .navigationBarHidden(true)
        }
    }
    
    // MARK: - Header Components
    
    private var personalizedHeader: some View {
        ProfileImageView(size: 44, showBorder: false, showEditIndicator: false, showWelcomeMessage: true)
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
        .padding(.bottom, 20)
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
                Text("\(currentData.years)")
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
                
                Text("End of Life*")
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
        .padding(.top, 20)
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
