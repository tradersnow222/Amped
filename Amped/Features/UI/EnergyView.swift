import SwiftUI
import Combine

/// Energy View - Shows battery-themed energy and activity tracking
struct EnergyView2: View {
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
        ZStack {
            Color.black.ignoresSafeArea(.all)
            LinearGradient.grayGradient.ignoresSafeArea()
            let isPremium = UserDefaults.standard.bool(forKey: "is_premium_user")
            if isPremium && selectedLifespanType == .potential {
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
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.leading)
                }
                Spacer()
            }
        }
        .padding(.top, 6)
    }
    
    // Glass card with inner countdown row – matches Figma composition
    private var lifespanDisplaySection: some View {
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
                    Text("Right now, your clock shows")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.85))
                        .padding(.top, 22)
                    
                    // Main years display
                    HStack(alignment: .lastTextBaseline, spacing: 8) {
                        Text("\(currentData.years)")
                            .font(.system(size: 72, weight: .bold))
                            .foregroundColor(Color(hex: "#F6C21A"))
                            .shadow(color: .black.opacity(0.25), radius: 4, x: 0, y: 2)
                        
                        Text("years")
                            .font(.system(size: 32, weight: .semibold))
                            .foregroundColor(.white.opacity(0.95))
                            .offset(y: -4)
                    }
                    
                    // Inner rounded countdown container
                    VStack {
                        HStack(spacing: 28) {
                            CountdownBox(value: "\(currentData.days)", label: "days")
                            CountdownBox(value: String(format: "%02d", currentData.hours), label: "hours")
                            CountdownBox(value: String(format: "%02d", currentData.minutes), label: "minutes")
                            CountdownBox(value: String(format: "%02d", currentData.seconds), label: "seconds")
//                            countdownColumn(value: "\(currentData.days)", label: "days")
//                            countdownColumn(value: String(format: "%02d", currentData.hours), label: "hours")
//                            countdownColumn(value: String(format: "%02d", currentData.minutes), label: "minutes")
//                            countdownColumn(value: String(format: "%02d", currentData.seconds), label: "seconds")
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
//                    .padding(.horizontal, 16)
                    .padding(.bottom, 20)
                }
//                .padding(.horizontal, 16)
//                .padding(.vertical, 8)
            }
//            .padding(.horizontal, 2)
        }
    }
    
    private var lifespanDisplaySection2: some View {
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
        ZStack {
//            LinearGradient.grayGradient.ignoresSafeArea()
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
                        VStack(spacing: 25) {
                            // Call to Action Section
                            callToActionSection
                            
                            // Lifespan Display
                            lifespanDisplaySection
                            
                            // Progress Bar Section
                            progressBarSection
                            
                            // Disclaimer
                            disclaimerSection
                        }
                        .padding(.horizontal, 24)   // Consistent page padding
                        .padding(.top, 5)         // Small top inset for content
                        .padding(.bottom, 32)      // Comfortable bottom space
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
    private var lifespanDisplaySection: some View {
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
                    Text("Right now, your clock shows")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.85))
                        .padding(.top, 22)
                    
                    // Main years display
                    HStack(alignment: .lastTextBaseline, spacing: 8) {
                        Text("\(currentData.years)")
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
                            countdownColumn(value: "\(currentData.days)", label: "days")
                            countdownColumn(value: String(format: "%02d", currentData.hours), label: "hours")
                            countdownColumn(value: String(format: "%02d", currentData.minutes), label: "minutes")
                            countdownColumn(value: String(format: "%02d", currentData.seconds), label: "seconds")
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
    private var progressBarSection: some View {
        VStack(spacing: 16) {
            // Centered title
            Text("Time Used: \(Int(currentData.progress * 100)) %")
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(Color(hex: "#00C853"))
                .frame(maxWidth: .infinity, alignment: .center)
            
            // Progress bar with embedded years
            GeometryReader { geometry in
                let totalWidth = geometry.size.width
                let trackHeight: CGFloat = 32
                let fillWidth = max(0, min(totalWidth, totalWidth * currentData.progress))
                
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
                                Text("\(currentData.birthYear)")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.white)
                                    .padding(.leading, 18)
                                Spacer()
                            }
                        )
                    
                    // Right year bubble at end
                    HStack {
                        Spacer()
                        Text("\(currentData.endYear)")
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
}

