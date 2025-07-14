import SwiftUI
@preconcurrency import Combine

// Adheres to: Modularization, Reusable UI Components (coding-standards.mdc)
// Adheres to: Apple Human Interface Guidelines (using standard shapes and text)

/// A reusable view that displays a battery indicator with customizable title, value, and charge level.
struct BatteryIndicatorView: View {
    let title: String
    let value: String
    let chargeLevel: CGFloat // 0.0 to 1.0
    let numberOfSegments: Int
    let useYellowGradient: Bool // To handle the different color scheme for the projection battery
    let internalText: String? // Optional text to display inside the battery
    let helpAction: (() -> Void)? // Optional action for tapping the info icon
    let showValueBelow: Bool // Whether to show the value below the battery
    
    // Realtime countdown properties  
    let lifeProjection: LifeProjection? // Optional life projection for realtime countdown
    let currentUserAge: Double? // Optional user age for realtime countdown
    
    @EnvironmentObject private var settingsManager: SettingsManager
    @Environment(\.glassTheme) private var glassTheme
    @State private var currentTime = Date()
    @State private var pulseAnimation = false
    
    // Timer for realtime updates - update every 1 second for proper countdown rate
    private let timer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()

    // Constants for visual styling - adjust as needed
    private let casingPadding: CGFloat = 8
    private let segmentSpacing: CGFloat = 4
    private let cornerRadius: CGFloat = 12
    private let glowRadius: CGFloat = 15
    private let casingLineWidth: CGFloat = 3
    private let terminalHeight: CGFloat = 10
    private let terminalWidthRatio: CGFloat = 0.2
    // Fixed battery height for consistency - reduced to show more health factors
    private let fixedBatteryHeight: CGFloat = 200  // Increased from 120 for bigger battery
    // Fixed overall card height for consistency between cards - reduced proportionally
    private let fixedCardHeight: CGFloat = 280  // Increased from 200 for bigger battery
    // Info button size
    private let infoButtonSize: CGFloat = 18
    // Title text font size - increased slightly for better visibility
    private let titleFontSize: CGFloat = 18

    // Define colors based on project assets
    private let greenColor = Color.ampedGreen
    private let yellowColor = Color.ampedYellow
    private let casingGradient = LinearGradient(
        gradient: Gradient(colors: [Color.ampedGreen.opacity(0.9), Color.ampedGreen.opacity(0.5)]),
        startPoint: .top,
        endPoint: .bottom
    )
    private let glowColor = Color.ampedGreen.opacity(0.7)
    private let emptySegmentColor = Color.gray.opacity(0.3) // Slightly more visible empty state

    // Split title into words
    private var titleWords: [String] {
        title.components(separatedBy: " ")
    }
    
    /// Display value with optional realtime countdown - just the number
    private var displayNumericValue: String {
        // Check if this is a lifespan display and realtime countdown is enabled
        if let projection = lifeProjection,
           let userAge = currentUserAge,
           title.contains("Lifespan remaining") || title.contains("remaining"),
           settingsManager.showRealtimeCountdown {
            
            let baseRemainingYears = projection.adjustedLifeExpectancyYears - userAge
            
            // Calculate time elapsed since start of current year to simulate countdown
            let calendar = Calendar.current
            let now = currentTime
            let startOfYear = calendar.dateInterval(of: .year, for: now)?.start ?? now
            let timeElapsed = now.timeIntervalSince(startOfYear)
            let yearsElapsed = timeElapsed / (365.25 * 24 * 3600)
            
            let preciseRemainingYears = baseRemainingYears - yearsElapsed
            
            // Format with high precision showing seconds as decimal places (8 decimal places) - just the number
            return String(format: "%.8f", max(preciseRemainingYears, 0.0))
        } else {
            // Use the original static value without unit
            return value.replacingOccurrences(of: " years", with: "")
                       .replacingOccurrences(of: " min", with: "")
                       .replacingOccurrences(of: " steps", with: "")
                       .replacingOccurrences(of: " bpm", with: "")
                       .replacingOccurrences(of: " kcal", with: "")
                       .replacingOccurrences(of: " hours", with: "")
        }
    }
    
    /// Display unit (e.g., "years", "min", etc.)
    private var displayUnit: String {
        // Check if this is a lifespan display
        if let _ = lifeProjection,
           let _ = currentUserAge,
           title.contains("Lifespan remaining") || title.contains("remaining") {
            return "years"
        } else {
            // Extract unit from original value if it exists
            if value.contains(" years") {
                return "years"
            } else if value.contains(" min") {
                return "min"
            } else if value.contains(" steps") {
                return "steps"
            } else if value.contains(" bpm") {
                return "bpm"
            } else if value.contains(" kcal") {
                return "kcal"
            } else if value.contains(" hours") {
                return "hours"
            } else {
                return "" // No unit for other values
            }
        }
    }

    var body: some View {
        VStack(spacing: 10) { // Reduced spacing for better layout
            // Title section with words stacked vertically - centered with overlaid info button
            if !title.isEmpty {
                ZStack {
                    // Centered title text taking full width
                    VStack(spacing: 0) {
                        ForEach(titleWords, id: \.self) { word in
                            Text(word)
                                .font(.system(size: titleFontSize, weight: .semibold))
                                .foregroundColor(.white)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .accessibility(addTraits: .isHeader)
                    
                    // Info button overlaid in top-right corner
                    if helpAction != nil {
                        HStack {
                            Spacer()
                            Button { 
                                HapticManager.shared.playSelection()
                                helpAction?() 
                            } label: {
                                Image(systemName: "info.circle.fill")
                                    .font(.system(size: infoButtonSize))
                                    .foregroundStyle(.quaternary)
                                    .symbolRenderingMode(.hierarchical)
                                    .accessibilityLabel("Information about \(title)")
                                    .accessibilityHint("Tap to learn more")
                            }
                            .buttonStyle(.plain)
                            .frame(width: 28, height: 28)
                            .contentShape(Circle())
                        }
                    }
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 8)
            }

            // Battery Body
            batteryBody()
                .frame(height: fixedBatteryHeight) // Fixed height for all batteries

            // Value display - separated number and unit for better readability
            if showValueBelow {
                VStack(spacing: 2) {
                    // Numeric value
                    Text(displayNumericValue)
                        .font(.system(size: 25, weight: .bold).monospacedDigit())
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    
                    // Unit (if exists)
                    if !displayUnit.isEmpty {
                        Text(displayUnit)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.horizontal, 8)
                .padding(.top, 4)
                .padding(.bottom, 4)
            }
        }
        .padding(EdgeInsets(top: 12, leading: 12, bottom: 16, trailing: 12)) // Reduced padding to give more space
        .frame(height: fixedCardHeight) // Fixed height for entire card
        .glassBackground(.regular, cornerRadius: cornerRadius * 1.5)
        .onAppear {
            // Trigger animations on appear
            // withAnimation(.easeInOut(duration: 0.5)) {
            //     animateSegments = true
            // }
            // Start pulse animation after a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation {
                    pulseAnimation = true
                }
            }
        }
        .onChange(of: chargeLevel) { _ in
            // Re-trigger animations when charge level changes
            // animateSegments = false
            pulseAnimation = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation {
                    pulseAnimation = true
                }
            }
        }
        .onReceive(timer) { _ in
            if settingsManager.showRealtimeCountdown && lifeProjection != nil && currentUserAge != nil {
                currentTime = Date()
            }
            // Toggle pulse animation every second for top segment
            pulseAnimation.toggle()
        }
    }

    // MARK: - Private Methods

    // Builds the main battery structure
    private func batteryBody() -> some View {
         GeometryReader { geometry in
             let totalHeight = geometry.size.height
             let totalWidth = geometry.size.width
             let batteryBodyHeight = totalHeight - terminalHeight
             
             // Calculate the actual interior space available for segments
             // We need extra padding inside the battery to ensure segments don't touch the casing
             let visualPadding: CGFloat = 8 // Extra visual padding inside the battery
             let totalInset = casingLineWidth + visualPadding
             let segmentContainerWidth = totalWidth - (totalInset * 2) - (casingPadding * 2)
             
             // Adjust segment container height to account for terminal and proper spacing
             let availableHeightForSegments = batteryBodyHeight - (totalInset * 2) - (casingPadding * 2)
             let totalSegmentSpacing = segmentSpacing * CGFloat(numberOfSegments - 1)
             let segmentHeight = (availableHeightForSegments - totalSegmentSpacing) / CGFloat(numberOfSegments)

             ZStack(alignment: .top) {
                 // Battery Terminal - Shiny Silver
                 RoundedRectangle(cornerRadius: cornerRadius / 3)
                     .fill(
                         LinearGradient(
                             gradient: Gradient(colors: [
                                 Color.white.opacity(0.9),
                                 Color.gray.opacity(0.8),
                                 Color.white.opacity(0.6),
                                 Color.gray.opacity(0.5)
                             ]),
                             startPoint: .top,
                             endPoint: .bottom
                         )
                     )
                     .frame(width: totalWidth * terminalWidthRatio, height: terminalHeight)
                     .shadow(color: Color.white.opacity(0.3), radius: 2, y: 1)

                 // Battery Casing with segments
                 ZStack {
                     // Background casing
                     RoundedRectangle(cornerRadius: cornerRadius)
                         .stroke(casingGradient, lineWidth: casingLineWidth)
                         // Removed grey background fill
                         .shadow(color: glowColor.opacity(0.8), radius: glowRadius, x: 0, y: 3)
                         .blur(radius: 0.5)
                         .frame(height: batteryBodyHeight)

                     // Battery Segments Container
                     VStack(spacing: segmentSpacing) {
                         ForEach(0..<numberOfSegments, id: \.self) { index in
                             let segmentIndexFromTop = numberOfSegments - 1 - index
                             let segmentFillThreshold = CGFloat(segmentIndexFromTop + 1) / CGFloat(numberOfSegments)
                             let isFilled = chargeLevel >= segmentFillThreshold
                             
                             // Check if this is the top filled segment
                             let isTopFilledSegment: Bool = {
                                 if !isFilled { return false }
                                 // Check if the segment above this one is NOT filled
                                 if segmentIndexFromTop == numberOfSegments - 1 {
                                     // This is the top segment, and it's filled
                                     return true
                                 } else {
                                     let aboveThreshold = CGFloat(segmentIndexFromTop + 2) / CGFloat(numberOfSegments)
                                     return chargeLevel < aboveThreshold
                                 }
                             }()
                             
                             RoundedRectangle(cornerRadius: cornerRadius / 2)
                                 .fill(segmentShapeStyle(isFilled: isFilled, threshold: segmentFillThreshold))
                                 .opacity(isTopFilledSegment && pulseAnimation ? 0.6 : 1.0)
                                 .animation(
                                     isTopFilledSegment ? .easeInOut(duration: 0.5) : nil,
                                     value: pulseAnimation
                                 )
                                 .frame(height: segmentHeight)
                         }
                     }
                     .frame(width: segmentContainerWidth)
                     .padding(.top, totalInset + casingPadding)
                     .padding(.bottom, totalInset + casingPadding)
                     .frame(height: batteryBodyHeight)
                     
                     // Overlay for Internal Text
                     if let text = internalText {
                         Text(text)
                             .font(.system(size: 14, weight: .bold))
                             .foregroundColor(Color.white)
                             .multilineTextAlignment(.center)
                             .padding(.horizontal, 4)
                             .shadow(color: .black.opacity(0.6), radius: 2, x: 0, y: 1)
                     }
                 }
                 .offset(y: terminalHeight)
             }
             .frame(width: totalWidth, height: totalHeight)
         }
    }

     // Custom shape for the battery casing including the terminal
     private func batteryCasingShape(casingWidth: CGFloat, casingHeight: CGFloat, terminalWidth: CGFloat, terminalHeight: CGFloat) -> some Shape {
         Path { path in
             let rect = CGRect(x: casingPadding, y: casingPadding + terminalHeight, width: casingWidth, height: casingHeight)
             let terminalRect = CGRect(x: casingPadding + (casingWidth - terminalWidth) / 2, y: casingPadding, width: terminalWidth, height: terminalHeight)

             // Main Body
             path.addRoundedRect(in: rect, cornerSize: CGSize(width: cornerRadius, height: cornerRadius))

             // Terminal
             let terminalCornerRadius: CGFloat = 4
             path.addRoundedRect(in: terminalRect, cornerSize: CGSize(width: terminalCornerRadius, height: terminalCornerRadius))
         }
     }

    // Determine segment material/color based on charge level
    private func segmentShapeStyle(isFilled: Bool, threshold: CGFloat) -> some ShapeStyle {
        if isFilled {
            let baseColor: Color
            if useYellowGradient {
                 let gradientFactor = (threshold - (1.0 / CGFloat(numberOfSegments)/2))
                 baseColor = Color.lerp(start: yellowColor, end: greenColor, t: gradientFactor) ?? greenColor
                 return baseColor
            } else {
                baseColor = greenColor
                return baseColor
            }
        } else {
            // Use a slightly reflective empty segment color
            return emptySegmentColor // Return the color directly
        }
    }

    // Helper View for default segment labels - now returns empty view as requested
    @ViewBuilder
    private func segmentLabelView(index: Int, segmentHeight: CGFloat) -> some View {
        // Return empty view to remove segment text as requested
        EmptyView()
    }

    // MARK: - Initializers
    
    /// Full initializer with all parameters including showValueBelow
    init(title: String, value: String, chargeLevel: CGFloat, numberOfSegments: Int, useYellowGradient: Bool, internalText: String?, helpAction: (() -> Void)?, lifeProjection: LifeProjection?, currentUserAge: Double?, showValueBelow: Bool = true) {
        self.title = title
        self.value = value
        self.chargeLevel = chargeLevel
        self.numberOfSegments = numberOfSegments
        self.useYellowGradient = useYellowGradient
        self.internalText = internalText
        self.helpAction = helpAction
        self.lifeProjection = lifeProjection
        self.currentUserAge = currentUserAge
        self.showValueBelow = showValueBelow
    }
    
    /// Convenience initializer for backwards compatibility (no realtime countdown)
    init(title: String, value: String, chargeLevel: CGFloat, numberOfSegments: Int, useYellowGradient: Bool, internalText: String?, helpAction: (() -> Void)?) {
        self.title = title
        self.value = value
        self.chargeLevel = chargeLevel
        self.numberOfSegments = numberOfSegments
        self.useYellowGradient = useYellowGradient
        self.internalText = internalText
        self.helpAction = helpAction
        self.lifeProjection = nil
        self.currentUserAge = nil
        self.showValueBelow = true // Default to showing value for backwards compatibility
    }
}

// Linear interpolation for color gradients (Helper)
// Consider moving this to a Color+Extensions file if used elsewhere
extension Color {
     static func lerp(start: Color, end: Color, t: CGFloat) -> Color? {
         guard let startComponents = start.cgColor?.components, let endComponents = end.cgColor?.components else {
             return nil // Handle cases where color conversion fails
         }

         let clampedT = max(0, min(1, t)) // Ensure t is between 0 and 1

         // Assuming RGBA components
         if startComponents.count >= 3 && endComponents.count >= 3 {
              let r = startComponents[0] + (endComponents[0] - startComponents[0]) * clampedT
              let g = startComponents[1] + (endComponents[1] - startComponents[1]) * clampedT
              let b = startComponents[2] + (endComponents[2] - startComponents[2]) * clampedT

              // Handle alpha if present
              let startAlpha = startComponents.count > 3 ? startComponents[3] : 1.0
              let endAlpha = endComponents.count > 3 ? endComponents[3] : 1.0
              let a = startAlpha + (endAlpha - startAlpha) * clampedT

              return Color(red: Double(r), green: Double(g), blue: Double(b), opacity: Double(a))
         }
         return nil // Component count mismatch
     }
}


// MARK: - Previews
struct BatteryIndicatorView_Previews: PreviewProvider {
    static var previews: some View {
        HStack(spacing: 20) {
            BatteryIndicatorView(
                title: "Today's Impact",
                value: "+15 min",
                chargeLevel: 0.6,
                numberOfSegments: 5,
                useYellowGradient: false,
                internalText: nil,
                helpAction: { print("Info tapped for Impact") },
                lifeProjection: nil,
                currentUserAge: nil
            )

            BatteryIndicatorView(
                title: "Lifespan remaining",
                value: "~46",
                chargeLevel: 0.8,
                numberOfSegments: 5,
                useYellowGradient: true,
                internalText: "Lifespan remaining: 46 years",
                helpAction: { print("Info tapped for Projection") },
                lifeProjection: nil,
                currentUserAge: nil
            )
        }
        .padding()
        .preferredColorScheme(.dark)
        .previewLayout(.sizeThatFits)
    }
} 