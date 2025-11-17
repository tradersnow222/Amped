//
//  EnergyView.swift
//  Amped
//
//  Created by Sheraz Hussain on 13/11/2025.
//

import SwiftUI
import Combine

/// Energy View - Shows battery-themed energy and activity tracking
struct EnergyView: View {
    // MARK: - State Variables
    @State private var selectedLifespanType: LifespanType = .current
    @State private var showingSettings = false
    
    @StateObject private var viewModel = DashboardViewModel()
    
    var onTapUnlock: (() -> Void)?
    
    // MARK: - Computed Properties
    private var currentLifespanData: LifespanData? {
        guard let projection = viewModel.lifeProjection else {
            return nil
        }
        
        let age = viewModel.currentUserAge
        let yearsRemaining = max(0, projection.adjustedLifeExpectancyYears - age)
        let breakdown = breakdownRemaining(from: yearsRemaining)
        let progressUsed = projection.adjustedLifeExpectancyYears > 0
            ? min(1.0, max(0.0, age / projection.adjustedLifeExpectancyYears))
            : 0.0
        
        let birthYear = viewModel.userProfile.birthYear ?? defaultBirthYear()
        let endYear = birthYear + Int(projection.adjustedLifeExpectancyYears.rounded())
        
        return LifespanData(
            years: Int(yearsRemaining.rounded(.down)),
            days: breakdown.days,
            hours: breakdown.hours,
            minutes: breakdown.minutes,
            seconds: breakdown.seconds,
            progress: progressUsed,
            birthYear: birthYear,
            endYear: endYear
        )
    }
    
    private var potentialLifespanData: LifespanData? {
        // Prefer optimal projection; otherwise use current projection as best available
        let base = viewModel.lifeProjection
        let optimal = viewModel.optimalHabitsProjection ?? viewModel.lifeProjection
        
        guard let best = optimal else {
            return nil
        }
        
        let age = viewModel.currentUserAge
        let yearsRemaining = max(0, best.adjustedLifeExpectancyYears - age)
        let breakdown = breakdownRemaining(from: yearsRemaining)
        let progressUsed = best.adjustedLifeExpectancyYears > 0
            ? min(1.0, max(0.0, age / best.adjustedLifeExpectancyYears))
            : 0.0
        
        let birthYear = viewModel.userProfile.birthYear ?? defaultBirthYear()
        let endYear = birthYear + Int(best.adjustedLifeExpectancyYears.rounded())
        
        // Extra years compared to current projection if available
        let extraYears: Double? = {
            guard let base = base else { return nil }
            let gain = best.adjustedLifeExpectancyYears - base.adjustedLifeExpectancyYears
            return gain > 0 ? gain : 0
        }()
        
        return LifespanData(
            years: Int(yearsRemaining.rounded(.down)),
            days: breakdown.days,
            hours: breakdown.hours,
            minutes: breakdown.minutes,
            seconds: breakdown.seconds,
            progress: progressUsed,
            birthYear: birthYear,
            endYear: endYear,
            extraYears: extraYears
        )
    }
    
    private var currentData: LifespanData? {
        selectedLifespanType == .current ? currentLifespanData : potentialLifespanData
    }
    
    var body: some View {
        ZStack {
            let isPremium = UserDefaults.standard.bool(forKey: "is_premium_user")
            if !isPremium && selectedLifespanType == .potential {
                UnlockSubscriptionView(buttonText: "Unlock Your Best Life by subcribing") {
                    // Got to subscription
                    onTapUnlock?()
                }
            } else {
                VStack(spacing: 12) {
                    // Header
                    personalizedHeader
                    
                    // Lifespan Toggle
                    lifespanToggle
                        .padding(.top, 4)
                    
                    // Main Content
                    ScrollView {
                        // Show loader until projections are available (and while loading)
                        if viewModel.isLoading ||
                            (selectedLifespanType == .current && viewModel.lifeProjection == nil) ||
                            (selectedLifespanType == .potential && viewModel.optimalHabitsProjection == nil && viewModel.lifeProjection == nil) {
                            
                            VStack(spacing: 16) {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: Color(hex: "#4DA3FF")))
                                Text("Loading your life clock…")
                                    .font(.system(size: 14, weight: .regular))
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            .frame(maxWidth: .infinity, minHeight: 240)
                            .padding(.horizontal, 24)
                            .padding(.top, 5)
                            .padding(.bottom, 82)
                        } else if let data = currentData {
                            VStack(spacing: 25) {
                                // Call to Action Section
                                callToActionSection
                                
                                // Lifespan Display
                                lifespanDisplaySection(data: data)
                                
                                // If showing potential, show “years gained” using actual projection delta
                                if selectedLifespanType == .potential, let extra = data.extraYears, extra > 0 {
                                    Text("+ \(String(format: "%.1f", extra)) years gained")
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundColor(Color(hex: "#51E1FA"))
                                        .frame(maxWidth: .infinity, alignment: .center)
                                }
                                
                                // Progress Bar Section
                                progressBarSection(data: data)
                                
                                // Disclaimer
                                disclaimerSection
                            }
                            .padding(.horizontal, 24)   // Consistent page padding
                            .padding(.top, 5)         // Small top inset for content
                            .padding(.bottom, 82)      // Comfortable bottom space
                        } else {
                            // No data state
                            VStack(spacing: 10) {
                                Text("No data available yet")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                Text("Connect Health data or complete your questionnaire to see your life clock.")
                                    .font(.system(size: 13, weight: .regular))
                                    .foregroundColor(.white.opacity(0.75))
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity, minHeight: 240)
                            .padding(.horizontal, 24)
                            .padding(.top, 5)
                            .padding(.bottom, 82)
                        }
                    }
                }
                .navigationBarHidden(true)
            }
        }
    }
    
    // MARK: - Header Components
    
    private var personalizedHeader: some View {
        ProfileImageView(size: 44, showBorder: false, showEditIndicator: false, showWelcomeMessage: false)
    }
    
    private var lifespanToggle: some View {
        HStack(spacing: 4) {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    selectedLifespanType = .current
                }
            }) {
                Text("Your Life Now")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(selectedLifespanType == .current ? .black : .white.opacity(0.6))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 100)
                            .fill(selectedLifespanType == .current ?
                                  LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color(hex: "#318AFC"),
                                        Color(hex: "#18EF47").opacity(0.58)
                                    ]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                  )
                                  : LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.clear,
                                        Color.clear
                                    ]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                  )
                                 )
                    )
            }
            
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    selectedLifespanType = .potential
                }
            }) {
                Text("Your Best Life")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(selectedLifespanType == .potential ? .white : .white.opacity(0.6))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 100)
                            .fill(selectedLifespanType == .potential ?
                                  LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color(hex: "#318AFC"),
                                        Color(hex: "#18EF47").opacity(0.58)
                                    ]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                  )
                                  : LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.clear,
                                        Color.clear
                                    ]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                  )
                                 )
                    )
            }
        }
        .padding(.horizontal, 2)
        .padding(.vertical, 2)
        .background(
            RoundedRectangle(cornerRadius: 100)
                .fill(Color.gray.opacity(0.3))
        )
        .padding(.horizontal, 24)
        .padding(.bottom, 20)
    }
    
    // MARK: - Main Content Sections
    
    // Matches “Your Life Clock” row from Figma
    private var callToActionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "#00C853"), Color(hex: "#F6C21A")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 36, height: 36)
                        .shadow(color: Color.black.opacity(0.25), radius: 6, x: 0, y: 3)
                    
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Your Life Clock")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text(selectedLifespanType == .current ?
                         "See how your daily habits shape your time second by second." :
                         "See how your optimized habits increase your time left second by second.")
                        .font(.system(size: 9, weight: .regular))
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.leading)
                }
                Spacer()
            }
        }
    }
    
    // Glass card with inner countdown row – matches Figma composition
    private func lifespanDisplaySection(data: LifespanData) -> some View {
        VStack(spacing: 16) {
            ZStack {
                // Outer glass card
                RoundedRectangle(cornerRadius: 28)
                    .fill(Color.white.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: 28)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color(hex: "#F6C21A").opacity(0.25),
                                        Color.white.opacity(0.08),
                                        Color(hex: "#00C853").opacity(0.25)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ),
                                lineWidth: 1.5
                            )
                    )
                    .shadow(color: .black.opacity(0.35), radius: 18, x: 0, y: 10)
                    .overlay(
                        // Soft inner edge highlight for depth
                        RoundedRectangle(cornerRadius: 28)
                            .stroke(Color.white.opacity(0.06), lineWidth: 6)
                            .blur(radius: 10)
                    )
                
                VStack(spacing: 22) {
                    // Caption
                    Text(selectedLifespanType == .current ? "Right now, your clock shows" : "With better choices, your clock shows")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.85))
                        .padding(.top, 22)
                    
                    // Main years display
                    HStack(alignment: .lastTextBaseline, spacing: 8) {
                        Text("\(data.years)")
                            .font(.system(size: 72, weight: .bold))
                            .foregroundColor(selectedLifespanType == .current ? Color(hex: "#F6C21A") : Color(hex: "#00C853"))
                            .shadow(color: .black.opacity(0.25), radius: 4, x: 0, y: 2)
                        
                        Text("years")
                            .font(.system(size: 32, weight: .semibold))
                            .foregroundColor(.white.opacity(0.95))
                            .offset(y: -4)
                    }
                    
                    // Inner rounded countdown container
                    VStack {
                        HStack(spacing: 20) {
                            countdownColumn(value: "\(data.days)", label: "days")
                            countdownColumn(value: String(format: "%02d", data.hours), label: "hours")
                            countdownColumn(value: String(format: "%02d", data.minutes), label: "minutes")
                            countdownColumn(value: String(format: "%02d", data.seconds), label: "seconds")
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 22)
                            .fill(Color.white.opacity(0.06))
                            .overlay(
                                RoundedRectangle(cornerRadius: 22)
                                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
                            )
                            .shadow(color: .black.opacity(0.25), radius: 8, x: 0, y: 4)
                    )
                    .padding(.horizontal, 10)
                    .padding(.bottom, 20)
                }
                .padding(.vertical, 8)
            }
        }
    }
    
    // Progress title + pill bar with year labels – matches Figma
    private func progressBarSection(data: LifespanData) -> some View {
        VStack(spacing: 16) {
            // Centered title
            Text("Time Used: \(Int(data.progress * 100)) %")
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(Color(hex: "#00C853"))
                .frame(maxWidth: .infinity, alignment: .center)
            
            // Progress bar with embedded years
            GeometryReader { geometry in
                let totalWidth = geometry.size.width
                let trackHeight: CGFloat = 32
                let fillWidth = max(0, min(totalWidth, totalWidth * data.progress))
                
                ZStack(alignment: .leading) {
                    // Track
                    Capsule()
                        .fill(Color.white.opacity(0.08))
                        .overlay(
                            Capsule().stroke(Color.white.opacity(0.10), lineWidth: 1)
                        )
                        .frame(height: trackHeight)
                    
                    // Fill
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "#3AA0FF"), Color(hex: "#4FC3F7")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: fillWidth, height: trackHeight)
                        .shadow(color: Color.black.opacity(0.25), radius: 6, x: 0, y: 3)
                        .overlay(
                            // Left year inside the fill
                            HStack {
                                Text("\(data.birthYear)")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.white)
                                    .padding(.leading, 18)
                                Spacer()
                            }
                        )
                    
                    // Right year bubble at end
                    HStack {
                        Spacer()
                        Text("\(data.endYear)")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white.opacity(0.9))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(selectedLifespanType == .current ? Color.clear : Color(hex: "#00C853"))
                                    .overlay(
                                        Capsule().stroke(selectedLifespanType == .current ? Color.clear : Color(hex: "#00C853"), lineWidth: 1)
                                    )
                            )
                            .padding(.trailing, 6)
                    }
                    .frame(height: trackHeight)
                }
            }
            .frame(height: 30)
            
            // Born and Projected End labels below progress bar
            HStack {
                Text("Born")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(.white.opacity(0.85))
                
                Spacer()
                
                Text("Projected End")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(.white.opacity(0.85))
            }
            .padding(.horizontal, 6)
        }
    }
    
    // Two-line centered attribution – matches Figma
    private var disclaimerSection: some View {
        VStack(spacing: 8) {
            Text("“Backed by 45 + peer-reviewed studies from")
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(.white.opacity(0.75))
                .multilineTextAlignment(.center)
            
            Text("Harvard, American Heart Association & Mayo Clinic”")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Color(hex: "#4DA3FF"))
                .multilineTextAlignment(.center)
        }
        .padding(.top, 8)
    }
    
    // MARK: - Supporting subviews for the card
    
    private func countdownColumn(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 28, weight: .semibold))
                .foregroundColor(.white)
                .monospacedDigit()
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white.opacity(0.75))
        }
        .frame(minWidth: 56)
    }
    
    // MARK: - Helpers (LifeProjection → LifespanData)
    
    private func defaultBirthYear() -> Int {
        let currentYear = Calendar.current.component(.year, from: Date())
        // If we don't have a stored birth year, infer from current age
        let inferred = currentYear - Int(viewModel.currentUserAge.rounded())
        return viewModel.userProfile.birthYear ?? inferred
    }
    
    private func breakdownRemaining(from yearsRemaining: Double) -> (days: Int, hours: Int, minutes: Int, seconds: Int) {
        // Ensure non-negative
        let clampedYears = max(0.0, yearsRemaining)
        
        // Separate whole years and fractional remainder
        let wholeYears = floor(clampedYears)
        let fractionalYears = clampedYears - wholeYears
        
        // Convert fractional years to days (using 365.25 average, but cap to 364 days)
        let totalDaysFromFraction = fractionalYears * 365.25
        let days = min(364, Int(totalDaysFromFraction.rounded(.down)))
        
        // Remaining fractional day after taking whole days
        let fractionalDay = max(0.0, totalDaysFromFraction - Double(days))
        
        // Hours, minutes, seconds from fractional day
        let totalHours = fractionalDay * 24.0
        let hours = Int(totalHours.rounded(.down))
        
        let totalMinutes = (totalHours - Double(hours)) * 60.0
        let minutes = Int(totalMinutes.rounded(.down))
        
        let seconds = Int(((totalMinutes - Double(minutes)) * 60.0).rounded(.down))
        
        return (days, hours, minutes, seconds)
    }
}

// MARK: - Supporting Views

struct CountdownBox: View {
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 28, weight: .semibold))
                .foregroundColor(.white)
                .monospacedDigit()
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white.opacity(0.75))
        }
        .frame(minWidth: 56)
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

