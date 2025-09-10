import SwiftUI
import HealthKit

/// Helper function to create category header for questions
func CategoryHeader(category: QuestionnaireViewModel.QuestionCategory) -> some View {
    // Applied rule: Simplicity is KING; match category style to scientific citation style
    VStack(spacing: 8) {
        HStack {
            Rectangle()
                .fill(Color.white.opacity(0.4))
                .frame(height: 1)

            Text(category.displayName)
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(.white.opacity(0.5))
                .padding(.horizontal, 12)
                .tracking(1.0)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .fixedSize(horizontal: true, vertical: false)

            Rectangle()
                .fill(Color.white.opacity(0.4))
                .frame(height: 1)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 12)
    }
}

// MARK: - Utilities
/// Removes the default dimming and background from SwiftUI .sheet for a clearer presentation
/// Simplicity is KING: small, focused modifier
struct ClearSheetBackground: ViewModifier {
    func body(content: Content) -> some View {
        Group {
            if #available(iOS 16.4, *) {
                content
                    .background(.clear)
                    .presentationBackground(.clear)
                    .presentationCornerRadius(0) // we'll handle corner shape inside the popup
            } else {
                content
                    .background(.clear)
            }
        }
    }
}

/// Interactive scientific citation view with popup
struct ScientificCitation: View {
    let text: String
    let metricType: HealthMetricType?
    @State private var showPopup = false
    
    var body: some View {
        HStack {
            Button(action: {
                if metricType != nil {
                    showPopup = true
                }
            }) {
                Image(systemName: metricType != nil ? "info.circle.fill" : "info.circle")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(metricType != nil ? 0.7 : 0.5))
            }
            .disabled(metricType == nil)
            
            Text(text)
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(.white.opacity(0.5))
                .lineLimit(2)
                .onTapGesture {
                    if metricType != nil {
                        showPopup = true
                    }
                }
        }
        .padding(.top, 8)
        .padding(.bottom, 40) // CRITICAL FIX: Consistent spacing between citation and buttons for all questions
        .sheet(isPresented: $showPopup) {
            if let type = metricType,
               let popup = ScientificCredibilityPopupFactory.createPopup(for: type, isPresented: $showPopup) {
                popup
                    .presentationDetents([.fraction(0.54)])
                    .presentationDragIndicator(.hidden)
                    .modifier(ClearSheetBackground())
            }
        }
    }
}

/// ULTRA-OPTIMIZED formatted button content - eliminates expensive string parsing
/// Pre-computes text components to prevent render-time performance issues
struct FormattedButtonText: View {
    private let primaryText: String
    private let parenthesesText: String?
    private let subtitle: String?
    
    // PERFORMANCE: Cache parsed components to avoid repeated string operations
    private static var textCache: [String: (primary: String, parentheses: String?)] = [:]
    
    init(text: String, subtitle: String? = nil) {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // PERFORMANCE: Use cached parsing results if available
        if let cached = Self.textCache[text] {
            self.primaryText = cached.primary
            self.parenthesesText = cached.parentheses
        } else {
            // PERFORMANCE: Optimized string parsing with minimal allocations
            let components = Self.optimizedParseText(text)
            Self.textCache[text] = components // Cache for future use
            self.primaryText = components.primary
            self.parenthesesText = components.parentheses
        }
        
        self.subtitle = subtitle
        
        let parseTime = CFAbsoluteTimeGetCurrent() - startTime
        if parseTime > 0.001 { // Only log if > 1ms
            print("🔍 PERFORMANCE_DEBUG: FormattedButtonText parsing took \(parseTime)s for '\(text.prefix(20))...'")
        }
    }
    
    var body: some View {
        VStack(spacing: 4) {
            Text(primaryText)
                .font(.system(size: 17, weight: .medium, design: .rounded))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
            
            // Show parentheses content as smaller, greyed subtext
            if let parenthesesText = parenthesesText {
                Text(parenthesesText)
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundColor(.white.opacity(0.65))
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            // Show additional subtitle if provided
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
    
    /// PERFORMANCE: Optimized text parsing with minimal string operations
    private static func optimizedParseText(_ text: String) -> (primary: String, parentheses: String?) {
        // PERFORMANCE: Single pass through string to find parentheses
        if let openParen = text.firstIndex(of: "("),
           let closeParen = text.lastIndex(of: ")"),
           openParen < closeParen {
            
            // Extract parentheses content efficiently
            let parenthesesRange = text.index(after: openParen)..<closeParen
            let parenthesesContent = String(text[parenthesesRange])
            
            // Extract primary text by removing parentheses line
            let primaryText = text.replacingOccurrences(
                of: text[openParen...closeParen],
                with: ""
            ).trimmingCharacters(in: .whitespacesAndNewlines)
            
            return (primary: primaryText, parentheses: parenthesesContent)
        }
        
        // No parentheses found - return as-is
        return (primary: text, parentheses: nil)
    }
}

/// Contains all the individual question views for the questionnaire
struct QuestionViews {
    
    // MARK: - Birthdate Question
    
    struct BirthdateQuestionView: View {
        @ObservedObject var viewModel: QuestionnaireViewModel
        var handleContinue: () -> Void
        
        // Local state for age input
        @State private var localAge: String = ""
        @State private var hasInitialized = false
        @FocusState private var isTextFieldFocused: Bool
        
        // Screen size adaptive spacing
        @Environment(\.adaptiveSpacing) private var spacing
        
        // Debounce timer for text input
        @State private var debounceTimer: Timer?
        
        var body: some View {
            VStack(spacing: 0) {
                Spacer()
                
                // Main content
                VStack(spacing: 32) {
                    // Emma character and text
                HStack(spacing: 0) {
                        // Emma character (steptwo)
                        Image("steptwo")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 68, height: 76)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("How many candles are on your birthday cake?")
                                .font(.system(size: 20, weight: .regular))
                                    .foregroundColor(.white)
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 24)
                    
                    VStack(spacing: 16) {
                        
                        // Text field with white background and custom placeholder
                        ZStack(alignment: .leading) {
                            // Custom placeholder
                            if localAge.isEmpty {
                                Text("Enter your age (eg. 35)")
                                    .font(.system(size: 14, weight: .regular))
                                    .foregroundColor(Color(red: 0.15, green: 0.15, blue: 0.15, opacity: 0.4))
                                    .padding(.horizontal, 20)
                                    .allowsHitTesting(false)
                            }
                            
                            TextField("", text: $localAge)
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(.black)
                                .multilineTextAlignment(.leading)
                                .padding(.vertical, 14)
                                .padding(.horizontal, 20)
                                .keyboardType(.numberPad)
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.white)
                        )
                        .accentColor(.black)
                        .focused($isTextFieldFocused)
                        .submitLabel(.continue)
                        .disableAutocorrection(true)
                        .onSubmit {
                            syncToViewModel()
                            if canProceedLocally {
                                proceedToNext()
                            }
                        }
                        .onChange(of: localAge) { newValue in
                            // Debounce sync to view model
                            debounceTimer?.invalidate()
                            debounceTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { _ in
                                syncToViewModel()
                            }
                        }
                .padding(.horizontal, 24)
                    }
                    
                    // Continue button
                    if canProceedLocally {
                        Button(action: {
                            proceedToNext()
                        }) {
                            Text("Continue")
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .padding(.horizontal, 24)
                        .padding(.bottom, 40)
                    } else {
                        Button(action: {
                            proceedToNext()
                        }) {
                            Text("Continue")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 100)
                                        .fill(Color.white.opacity(0.3))
                                )
                        }
                        .disabled(true)
                .padding(.horizontal, 24)
                        .padding(.bottom, 40)
                    }
                }
                Spacer()
            }
            .onAppear {
                if !hasInitialized {
                    localAge = viewModel.age > 0 ? String(viewModel.age) : ""
                    hasInitialized = true
                }
            }
            .onDisappear {
                debounceTimer?.invalidate()
                debounceTimer = nil
            }
        }
        
        // Local validation to avoid expensive view model property access
        private var canProceedLocally: Bool {
            guard let ageInt = Int(localAge.trimmingCharacters(in: .whitespacesAndNewlines)) else {
                return false
            }
            return ageInt >= 18 && ageInt <= 120
        }
        
        // Sync local state to view model efficiently
        private func syncToViewModel() {
            guard let ageInt = Int(localAge.trimmingCharacters(in: .whitespacesAndNewlines)),
                  ageInt >= 18 && ageInt <= 120 else {
                return
            }
            
            // Update the view model's age directly
            viewModel.setAge(ageInt)
        }
        
        private func proceedToNext() {
            guard canProceedLocally else { return }
            
            // Dismiss keyboard immediately to prevent animation conflicts
            isTextFieldFocused = false
            
            // Ensure view model is synced before proceeding
            syncToViewModel()
            
            // Cleanup timer
            debounceTimer?.invalidate()
            debounceTimer = nil
            
            // Use standard questionnaire transition timing to match other questions
            viewModel.proceedToNextQuestion()
        }
    }
    
    // MARK: - Name Question - NEW DESIGN WITH EMMA CHARACTER
    
    struct NameQuestionView: View {
        @ObservedObject var viewModel: QuestionnaireViewModel
        @FocusState private var isTextFieldFocused: Bool
        @Environment(\.adaptiveSpacing) private var spacing
        
        // CRITICAL KEYBOARD LAG FIX: Local state to prevent expensive view model updates during typing
        @State private var localUserName: String = ""
        @State private var hasInitialized = false
        
        
        var body: some View {
            VStack(spacing: 0) {
                Spacer()
                
                // Main content
                VStack(spacing: 32) {
                    // Emma character and text
                    HStack(spacing: 0) {
                        // Emma character (turtle with battery)
                        Image("steptwo")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 68, height: 76)
                    
                        // Image(avatarImageName)
                        //     .resizable()
                        //     .aspectRatio(contentMode: .fill)
                        //     .frame(width: 80, height: 80)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Let's get familiar")
                                .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.white)
                            
                            Text("I'm Emma your guide and companion in this journey.")
                                .font(.system(size: 16, weight: .regular))
                                .foregroundColor(.white.opacity(0.8))
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 24)
                    
                    VStack(spacing: 16) {
                    // Question - left aligned, font size 20, weight 500
                    HStack {
                        Text("What should I call you?")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.white)
                        Spacer()
                    }
                    .padding(.horizontal, 24)
                    
                    // Text field with white background and custom placeholder
                    ZStack(alignment: .leading) {
                        // Custom placeholder
                        if localUserName.isEmpty {
                            Text("Enter your full name")
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(Color(red: 0.15, green: 0.15, blue: 0.15, opacity: 0.4))
                        .padding(.horizontal, 20)
                                .allowsHitTesting(false)
                        }
                        
                        TextField("", text: $localUserName)
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(.black)
                            .multilineTextAlignment(.leading)
                            .padding(.vertical, 14)
                            .padding(.horizontal, 20)
                    }
                        .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.white)
                    )
                    .accentColor(.black)
                        .focused($isTextFieldFocused)
                        .textInputAutocapitalization(.words)
                        .textContentType(.givenName)
                        .submitLabel(.continue)
                        .disableAutocorrection(true)
                        .onSubmit {
                            syncToViewModel()
                            if canProceedLocally {
                                proceedToNext()
                            }
                        }
                        .onChange(of: localUserName) { newValue in
                            // Debounce sync to view model
                            debounceTimer?.invalidate()
                            debounceTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { _ in
                                syncToViewModel()
                            }
                        }
                        .padding(.horizontal, 24)
                        }
                    
                // Continue button
                if canProceedLocally {
                    Button(action: {
                        proceedToNext()
                    }) {
                        Text("Continue")
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                } else {
                    Button(action: {
                        proceedToNext()
                    }) {
                        Text("Continue")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 100)
                                    .fill(Color.white.opacity(0.3))
                            )
                    }
                    .disabled(true)
                .padding(.horizontal, 24)
                    .padding(.bottom, 40)
            }
                }
                Spacer()
            }
            .onAppear {
                if !hasInitialized {
                    localUserName = viewModel.userName
                    hasInitialized = true
                }
            }
            .onDisappear {
                debounceTimer?.invalidate()
                debounceTimer = nil
            }
        }
        
        
        // KEYBOARD LAG FIX: Debounce timer for expensive operations
        @State private var debounceTimer: Timer?
        
        // Local validation to avoid expensive view model property access
        private var canProceedLocally: Bool {
            !localUserName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        
        
        // KEYBOARD LAG FIX: Sync local state to view model efficiently
        private func syncToViewModel() {
            // Only sync if actually different to avoid unnecessary updates
            if viewModel.userName != localUserName {
                viewModel.userName = localUserName
            }
        }
        
        private func proceedToNext() {
            guard canProceedLocally else { return }
            
            // KEYBOARD TRANSITION FIX: Dismiss keyboard immediately to prevent animation conflicts
            isTextFieldFocused = false
            
            // Ensure view model is synced before proceeding
            syncToViewModel()
            
            // Cleanup timer
            debounceTimer?.invalidate()
            debounceTimer = nil
            
            // Use standard questionnaire transition timing to match other questions
            viewModel.proceedToNextQuestion()
        }
    }
    
    // MARK: - Stress Level Question
    
    struct Triangle: Shape {
        func path(in rect: CGRect) -> Path {
            var path = Path()
            path.move(to: CGPoint(x: rect.midX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            path.closeSubpath()
            return path
        }
    }
    
    struct StressQuestionView: View {
        @ObservedObject var viewModel: QuestionnaireViewModel
        @Environment(\.adaptiveSpacing) private var spacing
        @State private var showPopup = false
        @State private var showDrawer = false
        
        var body: some View {
            VStack(alignment: .center, spacing: 0) {
                Spacer()
                
                // Emma character and question layout
                HStack(alignment: .top, spacing: 16) {
                    VStack(alignment: .leading, spacing: 12){
                        HStack(alignment: .center, spacing: 0){
                            // Emma character
                            Image("steptwo")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 68, height: 76)
                            
                            // Question text
                            VStack(alignment: .leading, spacing: 8) {
                                Text("How would you describe your typical stress level?")
                                    .font(.system(size: 20, weight: .medium))
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.leading)
                                    .lineLimit(nil)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .frame(maxWidth: .infinity, alignment: .leading)

                            }
                        }
                        // Research citation with book icon
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showDrawer = true
                            }
                        }) {
                            HStack(spacing: 6) {
                                Image("book_ribbon")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 16, height: 16)
                                
                                Text("Tap to see what research based on 195 studies tell us.")
                                    .font(.system(size: 12, weight: .regular))
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    Spacer()
                }
                .padding(.horizontal, 24)
                
                Spacer()
                 .frame(maxHeight: 32)
                
                // Stress level options
                VStack(spacing: 16) {
                    ForEach(QuestionnaireViewModel.StressLevel.allCases, id: \.self) { stressLevel in
                        Button(action: {
                            viewModel.selectedStressLevel = stressLevel
                            viewModel.proceedToNextQuestion()
                        }) {
                            VStack(alignment: .center, spacing: 4) {
                                Text(stressLevel.mainText)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                
                                Text(stressLevel.subText)
                                    .font(.system(size: 14, weight: .regular))
                                    .foregroundColor(.gray)
                                    .frame(maxWidth: .infinity, alignment: .center)
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 100)
                                    .fill(Color.black)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 100)
                                            .stroke(
                                                LinearGradient(
                                                    colors: [Color("ampedGreen"), Color("ampedYellow")],
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                ),
                                                lineWidth: 1
                                            )
                                    )
                            )
                        }
                        .hapticFeedback(.light)
                    }
            }
            .padding(.horizontal, 24)
                
                Spacer()
            }
            .frame(maxHeight: .infinity)
            .ignoresSafeArea(.container, edges: .bottom)
            .overlay(
                // Popup overlay
                Group {
                    if showPopup {
                        Color.black.opacity(0.5)
                            .ignoresSafeArea()
                            .onTapGesture {
                                UserDefaults.standard.set(true, forKey: "stressPopupShown")
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    showPopup = false
                                }
                            }
                        
                        // Popup content
                        VStack(spacing: 0) {
                            // Speech bubble arrow
                            Triangle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(
                                        stops: [
                                            .init(color: Color(red: 0.00, green: 0.57, blue: 0.27), location: 0.0),  // #009245
                                            .init(color: Color(red: 0.49, green: 0.75, blue: 0.20), location: 0.9), // #7EC033
                                            .init(color: Color(red: 0.99, green: 0.93, blue: 0.13), location: 1.0), // #FCEE21
                                        ]
                                        ),
                                        // startPoint: UnitPoint(x: 0.35, y: 0.12), // 232.42deg equivalent
                                        // endPoint: UnitPoint(x: 0.89, y: 0.89)
                                        startPoint: .bottomLeading,
                                        endPoint: .topTrailing
                                    )
                                )
                                .frame(width: 20, height: 12)
                                .offset(y: 5)
                            
                            // Popup content
                            VStack(spacing: 16) {
                                Text("Tap to see how this habit impacts lifespan")
                                    .font(.system(size: 20, weight: .regular))
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.leading)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                Button(action: {
                                    UserDefaults.standard.set(true, forKey: "stressPopupShown")
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        showPopup = false
                                    }
                                }) {
                                    Text("Okay")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(Color("ampedGreen"))
                                        .padding(.horizontal, 24)
                                        .padding(.vertical, 12)
                                        .background(
                                            RoundedRectangle(cornerRadius: 20)
                                                .fill(Color.white)
                                        )
                                }
                            }
                            .padding(.horizontal, 24)
                            .padding(.vertical, 32)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(
                                         LinearGradient(
                                        gradient: Gradient(
                                        stops: [
                                           .init(color: Color(red: 0/255, green: 146/255, blue: 69/255), location: 0.0707),
                                            .init(color: Color(red: 63/255, green: 169/255, blue: 60/255), location: 0.291),
                                            .init(color: Color(red: 126/255, green: 192/255, blue: 51/255), location: 0.5908),
                                            .init(color: Color(red: 252/255, green: 238/255, blue: 33/255), location: 0.8026)
                                        ]
                                        ),
                                        // startPoint: UnitPoint(x: 0.35, y: 0.12), // 232.42deg equivalent
                                        // endPoint: UnitPoint(x: 0.89, y: 0.89)
                                        startPoint: .bottomLeading,
                                        endPoint: .topTrailing
                                    )
                            )
                            )
                        }
                        .padding(.horizontal, 40)
                        .transition(.scale.combined(with: .opacity))
                    }
                }
            )
            .overlay(
                // Drawer overlay
                Group {
                    if showDrawer {
                        ZStack(alignment: .bottom) {
                            // Transparent background overlay
                            Color.clear
                                .ignoresSafeArea(.all)
                                .onTapGesture {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        showDrawer = false
                                    }
                                }
                            
                            // Drawer content - positioned at bottom
                            VStack(spacing: 0) {
                                // Handle bar (draggable)
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color.white)
                                    .frame(width: 40, height: 4)
                                    .padding(.top, 8)
                                    .padding(.bottom, 20)
                                    .onTapGesture {
                                        withAnimation(.easeInOut(duration: 0.3)) {
                                            showDrawer = false
                                        }
                                    }
                                
                                VStack(alignment: .leading, spacing: 20) {
                                    // Header
                                    HStack {
                                        Text("Impact score")
                                            .font(.system(size: 18, weight: .regular))
                                            .foregroundColor(.white)
                                        
                                        Spacer()
                                        
                                        Button(action: {
                                            withAnimation(.easeInOut(duration: 0.3)) {
                                                showDrawer = false
                                            }
                                        }) {
                                            Image(systemName: "xmark")
                                                .font(.system(size: 16, weight: .medium))
                                                .foregroundColor(.white)
                                        }
                                    }
                                    
                                    // Score display
                                    HStack(alignment: .bottom, spacing: 0) {
                                        Text("50")
                                            .font(.system(size: 48, weight: .bold))
                                            .foregroundColor(.white)
                                        
                                        Text("/100")
                                            .font(.system(size: 24, weight: .regular))
                                            .foregroundColor(.white)
                                            .padding(.bottom, 8)
                                    }
                                    
                                    // Slider
                                    VStack(alignment: .leading, spacing: 8) {
                                        // Custom slider
                                        GeometryReader { geometry in
                                            ZStack(alignment: .leading) {
                                                // Background track
                                                RoundedRectangle(cornerRadius: 4)
                                                    .fill(Color.white)
                                                    .frame(height: 8)
                                                
                                                // Progress track
                                                RoundedRectangle(cornerRadius: 4)
                                                    .fill(Color("ampedYellow"))
                                                    .frame(width: geometry.size.width * 0.5, height: 8)
                                                
                                                // Thumb
                                                Circle()
                                                    .fill(Color.gray)
                                                    .frame(width: 20, height: 20)
                                                    .offset(x: geometry.size.width * 0.5 - 10)
                                            }
                                        }
                                        .frame(height: 20)
                                        
                                        // Range labels
                                        HStack {
                                            Text("0")
                                                .font(.system(size: 12, weight: .regular))
                                                .foregroundColor(.gray)
                                            
                                            Spacer()
                                            
                                            Text("100")
                                                .font(.system(size: 12, weight: .regular))
                                                .foregroundColor(.gray)
                                        }
                                    }
                                    
                                    // Description text
                                    VStack(alignment: .leading, spacing: 12) {
                                        Text("This score estimates how your stress level affects your life expectancy.")
                                            .font(.system(size: 16, weight: .regular))
                                            .foregroundColor(.white)
                                            .multilineTextAlignment(.leading)
                                        
                                        Text("Stress contributes to 30% of your total lifespan impact. It's important!")
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundColor(.white)
                                            .multilineTextAlignment(.leading)
                                        
                                        Text("Chronic stress increases mortality risk by 43% compared to low stress levels.")
                                            .font(.system(size: 14, weight: .regular))
                                            .foregroundColor(.white)
                                            .multilineTextAlignment(.leading)
                                    }
                                    
                                    // Source button
                                    Button(action: {
                                        // Handle source link tap
                                    }) {
                                        HStack {
                                            Text("Source: Keller A (2012)")
                                                .font(.system(size: 12, weight: .regular))
                                                .foregroundColor(.white)
                                            
                                            Image(systemName: "arrow.up.right")
                                                .font(.system(size: 12, weight: .regular))
                                                .foregroundColor(.white)
                                        }
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(Color.gray.opacity(0.3))
                                        )
                                    }
                                    .padding(.bottom, 20)
                                }
                                .padding(.horizontal, 24)
                            }
                            .background(
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .fill(Color(red: 0x27/255, green: 0x27/255, blue: 0x27/255)) // #272727
                            )
                            .ignoresSafeArea(.all)
                        }
                        .ignoresSafeArea(.all)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
            )
            .onAppear {
                // Show popup only once when view appears
                if !UserDefaults.standard.bool(forKey: "stressPopupShown") {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showPopup = true
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Anxiety Level Question
    struct RoundedCorner: Shape {
        var radius: CGFloat = 16
        var corners: UIRectCorner = .allCorners
        
        func path(in rect: CGRect) -> Path {
            let path = UIBezierPath(
                roundedRect: rect,
                byRoundingCorners: corners,
                cornerRadii: CGSize(width: radius, height: radius)
            )
            return Path(path.cgPath)
        }
    }
    
    struct AnxietyQuestionView: View {
        @ObservedObject var viewModel: QuestionnaireViewModel
        @Environment(\.adaptiveSpacing) private var spacing
        @State private var showPopup = false
        @State private var showDrawer = false
        
        var body: some View {
            VStack(alignment: .center, spacing: 0) {
                Spacer()
                
                // Emma character and question layout
                HStack(alignment: .top, spacing: 16) {
                    VStack(alignment: .leading, spacing: 12){
                        HStack(alignment: .center, spacing: 0){
                            // Emma character
                            Image("steptwo")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 68, height: 76)
                            
                            // Question text
                            VStack(alignment: .leading, spacing: 8) {
                                Text("How would you describe your anxiety level?")
                                    .font(.system(size: 20, weight: .medium))
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.leading)
                                    .lineLimit(nil)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .frame(maxWidth: .infinity, alignment: .leading)

                            }
                        }
                        // Research citation with book icon
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showDrawer = true
                            }
                        }) {
                            HStack(spacing: 6) {
                                Image("book_ribbon")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 16, height: 16)
                                
                                Text("Tap to see what research based on 195 studies tell us.")
                                    .font(.system(size: 12, weight: .regular))
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    Spacer()
                }
                .padding(.horizontal, 24)
                
                Spacer()
                 .frame(maxHeight: 32)
                
                // Anxiety level options
                VStack(spacing: 16) {
                    ForEach(QuestionnaireViewModel.AnxietyLevel.allCases, id: \.self) { anxietyLevel in
                        Button(action: {
                            viewModel.selectedAnxietyLevel = anxietyLevel
                            viewModel.proceedToNextQuestion()
                        }) {
                            VStack(alignment: .center, spacing: 4) {
                                Text(anxietyLevel.mainText)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                
                                Text(anxietyLevel.subText)
                                    .font(.system(size: 14, weight: .regular))
                                    .foregroundColor(.gray)
                                    .frame(maxWidth: .infinity, alignment: .center)
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 100)
                                    .fill(Color.black)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 100)
                                            .stroke(
                                                LinearGradient(
                                                    colors: [Color("ampedGreen"), Color("ampedYellow")],
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                ),
                                                lineWidth: 1
                                            )
                                    )
                            )
                        }
                        .hapticFeedback(.light)
                    }
            }
            .padding(.horizontal, 24)
                
                Spacer()
            }
            .frame(maxHeight: .infinity)
            .ignoresSafeArea(.container, edges: .bottom)
            .overlay(
                // Popup overlay
                Group {
                    if showPopup {
                        Color.black.opacity(0.5)
                            .ignoresSafeArea()
                            .onTapGesture {
                                UserDefaults.standard.set(true, forKey: "anxietyPopupShown")
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    showPopup = false
                                }
                            }
                        
                        // Popup content
                        VStack(spacing: 0) {
                            // Speech bubble arrow
                            Triangle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(
                                        stops: [
                                            .init(color: Color(red: 0.00, green: 0.57, blue: 0.27), location: 0.0),  // #009245
                                            .init(color: Color(red: 0.49, green: 0.75, blue: 0.20), location: 0.9), // #7EC033
                                            .init(color: Color(red: 0.99, green: 0.93, blue: 0.13), location: 1.0), // #FCEE21
                                        ]
                                        ),
                                        // startPoint: UnitPoint(x: 0.35, y: 0.12), // 232.42deg equivalent
                                        // endPoint: UnitPoint(x: 0.89, y: 0.89)
                                        startPoint: .bottomLeading,
                                        endPoint: .topTrailing
                                    )
                                )
                                .frame(width: 20, height: 12)
                                .offset(y: 5)
                            
                            // Popup content
                            VStack(spacing: 16) {
                                Text("Tap to see how this habit impacts lifespan")
                                    .font(.system(size: 20, weight: .regular))
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.leading)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                Button(action: {
                                    UserDefaults.standard.set(true, forKey: "anxietyPopupShown")
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        showPopup = false
                                    }
                                }) {
                                    Text("Okay")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(Color("ampedGreen"))
                                        .padding(.horizontal, 24)
                                        .padding(.vertical, 12)
                                        .background(
                                            RoundedRectangle(cornerRadius: 20)
                                                .fill(Color.white)
                                        )
                                }
                            }
                            .padding(.horizontal, 24)
                            .padding(.vertical, 32)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(
                                         LinearGradient(
                                        gradient: Gradient(
                                        stops: [
                                           .init(color: Color(red: 0/255, green: 146/255, blue: 69/255), location: 0.0707),
                                            .init(color: Color(red: 63/255, green: 169/255, blue: 60/255), location: 0.291),
                                            .init(color: Color(red: 126/255, green: 192/255, blue: 51/255), location: 0.5908),
                                            .init(color: Color(red: 252/255, green: 238/255, blue: 33/255), location: 0.8026)
                                        ]
                                        ),
                                        // startPoint: UnitPoint(x: 0.35, y: 0.12), // 232.42deg equivalent
                                        // endPoint: UnitPoint(x: 0.89, y: 0.89)
                                        startPoint: .bottomLeading,
                                        endPoint: .topTrailing
                                    )
                            )
                            )
                        }
                        .padding(.horizontal, 40)
                        .transition(.scale.combined(with: .opacity))
                    }
                }
            )
            .overlay(
                // Drawer overlay
                Group {
                    if showDrawer {
                        ZStack(alignment: .bottom) {
                            // Transparent background overlay
                            Color.clear
                                .ignoresSafeArea(.all)
                                .onTapGesture {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        showDrawer = false
                                    }
                                }
                            
                            // Drawer content - positioned at bottom
                            VStack(spacing: 0) {
                                // Handle bar (draggable)
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color.white)
                                    .frame(width: 40, height: 4)
                                    .padding(.top, 8)
                                    .padding(.bottom, 20)
                                    .onTapGesture {
                                        withAnimation(.easeInOut(duration: 0.3)) {
                                            showDrawer = false
                                        }
                                    }
                                
                                VStack(alignment: .leading, spacing: 20) {
                                    // Header
                                    HStack {
                                        Text("Impact score")
                                            .font(.system(size: 18, weight: .regular))
                                            .foregroundColor(.white)
                                        
                                        Spacer()
                                        
                                        Button(action: {
                                            withAnimation(.easeInOut(duration: 0.3)) {
                                                showDrawer = false
                                            }
                                        }) {
                                            Image(systemName: "xmark")
                                                .font(.system(size: 16, weight: .medium))
                                                .foregroundColor(.white)
                                        }
                                    }
                                    
                                    // Score display
                                    HStack(alignment: .bottom, spacing: 0) {
                                        Text("50")
                                            .font(.system(size: 48, weight: .bold))
                                            .foregroundColor(.white)
                                        
                                        Text("/100")
                                            .font(.system(size: 24, weight: .regular))
                                            .foregroundColor(.white)
                                            .padding(.bottom, 8)
                                    }
                                    
                                    // Slider
                                    VStack(alignment: .leading, spacing: 8) {
                                        // Custom slider
                                        GeometryReader { geometry in
                                            ZStack(alignment: .leading) {
                                                // Background track
                                                RoundedRectangle(cornerRadius: 4)
                                                    .fill(Color.white)
                                                    .frame(height: 8)
                                                
                                                // Progress track
                                                RoundedRectangle(cornerRadius: 4)
                                                    .fill(Color("ampedYellow"))
                                                    .frame(width: geometry.size.width * 0.5, height: 8)
                                                
                                                // Thumb
                                                Circle()
                                                    .fill(Color.gray)
                                                    .frame(width: 20, height: 20)
                                                    .offset(x: geometry.size.width * 0.5 - 10)
                                            }
                                        }
                                        .frame(height: 20)
                                        
                                        // Range labels
                                        HStack {
                                            Text("0")
                                                .font(.system(size: 12, weight: .regular))
                                                .foregroundColor(.gray)
                                            
                                            Spacer()
                                            
                                            Text("100")
                                                .font(.system(size: 12, weight: .regular))
                                                .foregroundColor(.gray)
                                        }
                                    }
                                    
                                    // Description text
                                    VStack(alignment: .leading, spacing: 12) {
                                        Text("This score estimates how your anxiety level affects your life expectancy.")
                                            .font(.system(size: 16, weight: .regular))
                                            .foregroundColor(.white)
                                            .multilineTextAlignment(.leading)
                                        
                                        Text("Anxiety contributes to 30% of your total lifespan impact. It's important!")
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundColor(.white)
                                            .multilineTextAlignment(.leading)
                                        
                                        Text("Chronic anxiety increases mortality risk by 43% compared to low anxiety levels.")
                                            .font(.system(size: 14, weight: .regular))
                                            .foregroundColor(.white)
                                            .multilineTextAlignment(.leading)
                                    }
                                    
                                    // Source button
                                    Button(action: {
                                        // Handle source link tap
                                    }) {
                                        HStack {
                                            Text("Source: Keller A (2012)")
                                                .font(.system(size: 12, weight: .regular))
                                                .foregroundColor(.white)
                                            
                                            Image(systemName: "arrow.up.right")
                                                .font(.system(size: 12, weight: .regular))
                                                .foregroundColor(.white)
                                        }
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(Color.gray.opacity(0.3))
                                        )
                                    }
                                    .padding(.bottom, 20)
                                }
                                .padding(.horizontal, 24)
                            }
                            .background(
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .fill(Color(red: 0x27/255, green: 0x27/255, blue: 0x27/255)) // #272727
                            )
                            .ignoresSafeArea(.all)
                        }
                        .ignoresSafeArea(.all)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
            )
            .onAppear {
                // Show popup only once when view appears
                if !UserDefaults.standard.bool(forKey: "anxietyPopupShown") {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showPopup = true
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Gender Question
    
    struct GenderQuestionView: View {
        @ObservedObject var viewModel: QuestionnaireViewModel
        @Environment(\.adaptiveSpacing) private var spacing
        @State private var isDropdownExpanded = false
        
        var body: some View {
            VStack(spacing: 0) {
                Spacer()
                
                // Main content
                VStack(spacing: 32) {
                    // Emma character and text
                    HStack(spacing: 0) {
                        // Emma character (steptwo)
                        Image("steptwo")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 68, height: 76)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Quick question: are you Team He, She, or They?")
                                .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.white)
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 24)
                    
                    VStack(spacing: 16) {
                        // Dropdown field
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isDropdownExpanded.toggle()
                            }
                        }) {
                            HStack {
                                Text(selectedGenderText)
                                    .font(.system(size: 14, weight: .regular))
                                    .foregroundColor(selectedGenderText == "Select an option" ? Color(red: 0.15, green: 0.15, blue: 0.15, opacity: 0.4) : .black)
                                
                                Spacer()
                                
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.black)
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: isDropdownExpanded ? 12 : 6)
                                    .fill(Color.white)
                            )
                        }
                        .padding(.horizontal, 24)
                        
                        // Continue button
                        if viewModel.selectedGender != nil {
                            Button(action: {
                            viewModel.proceedToNextQuestion()
                        }) {
                                Text("Continue")
                            }
                            .buttonStyle(PrimaryButtonStyle())
                            .padding(.horizontal, 24)
                            .padding(.bottom, 40)
                        } else {
                            Button(action: {
                                viewModel.proceedToNextQuestion()
                            }) {
                                Text("Continue")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(
                                        RoundedRectangle(cornerRadius: 100)
                                            .fill(Color.white.opacity(0.3))
                                    )
                            }
                            .disabled(true)
                            .padding(.horizontal, 24)
                            .padding(.bottom, 40)
                        }
                    }
                }
                Spacer()
            }
            .overlay(
                // Dropdown overlay
                Group {
                    if isDropdownExpanded {
                        VStack(spacing: 0) {
                            // Position the dropdown below the input field
                            Spacer()
                                .frame(height: 360)
                            
                            // Unified dropdown container
                            VStack(spacing: 0) {
                                // First option (Male)
                                Button(action: {
                                    viewModel.selectedGender = .male
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        isDropdownExpanded = false
                                    }
                                }) {
                                    HStack {
                                        Text("Male")
                                            .font(.system(size: 14, weight: .regular))
                                            .foregroundColor(.black)
                                        Spacer()
                                    }
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 14)
                                }
                                
                                // Divider
                                Rectangle()
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(height: 1)
                                
                                // Second option (Female)
                                Button(action: {
                                    viewModel.selectedGender = .female
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        isDropdownExpanded = false
                                    }
                                }) {
                                    HStack {
                                        Text("Female")
                                            .font(.system(size: 14, weight: .regular))
                                            .foregroundColor(.black)
                                        Spacer()
                                    }
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 14)
                                }
                                
                                // Divider
                                Rectangle()
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(height: 1)
                                
                                // Third option (Prefer not to say)
                                Button(action: {
                                    viewModel.selectedGender = .preferNotToSay
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        isDropdownExpanded = false
                                    }
                                }) {
                                    HStack {
                                        Text("Prefer not to say")
                                            .font(.system(size: 14, weight: .regular))
                                            .foregroundColor(.black)
                                        Spacer()
                                    }
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 14)
                                }
                            }
                            .background(Color.white)
                            .cornerRadius(12)
                            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
            .padding(.horizontal, 24)
                            
                            Spacer()
                        }
                        .background(Color.black.opacity(0.3))
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isDropdownExpanded = false
                            }
                        }
                    }
                }
            )
        }
        
        private var selectedGenderText: String {
            switch viewModel.selectedGender {
            case .male:
                return "Male"
            case .female:
                return "Female"
            case .preferNotToSay:
                return "Prefer not to say"
            case .none:
                return "Select an option"
            }
        }
    }
    
    // MARK: - Nutrition Question
    
    struct NutritionQuestionView: View {
        @ObservedObject var viewModel: QuestionnaireViewModel
        @Environment(\.adaptiveSpacing) private var spacing
        @State private var showPopup = false
        @State private var showDrawer = false
        
        var body: some View {
            VStack(alignment: .center, spacing: 0) {
                Spacer()
                
                // Emma character and question layout
                HStack(alignment: .top, spacing: 16) {
                    VStack(alignment: .leading, spacing: 12){
                        HStack(alignment: .center, spacing: 0){
                            // Emma character
                            Image("steptwo")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 68, height: 76)
                            
                            // Question text
                            VStack(alignment: .leading, spacing: 8) {
                                Text("How would you describe your typical diet?")
                                    .font(.system(size: 20, weight: .medium))
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.leading)
                                    .lineLimit(nil)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .frame(maxWidth: .infinity, alignment: .leading)

                            }
                        }
                        // Research citation with book icon
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showDrawer = true
                            }
                        }) {
                            HStack(spacing: 6) {
                                Image("book_ribbon")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 16, height: 16)
                                
                                Text("Tap to see what research based on 195 studies tell us.")
                                    .font(.system(size: 12, weight: .regular))
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    Spacer()
                }
                .padding(.horizontal, 24)
                
                Spacer()
                 .frame(maxHeight: 32)
                
                // Diet quality options
                VStack(spacing: 16) {
                    ForEach(QuestionnaireViewModel.NutritionQuality.allCases, id: \.self) { nutrition in
                        Button(action: {
                            viewModel.selectedNutritionQuality = nutrition
                            viewModel.proceedToNextQuestion()
                        }) {
                            VStack(alignment: .center, spacing: 4) {
                                Text(nutrition.mainText)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                
                                Text(nutrition.subText)
                                    .font(.system(size: 14, weight: .regular))
                                    .foregroundColor(.gray)
                                    .frame(maxWidth: .infinity, alignment: .center)
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 100)
                                    .fill(Color.black)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 100)
                                            .stroke(
                                                LinearGradient(
                                                    colors: [Color("ampedGreen"), Color("ampedYellow")],
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                ),
                                                lineWidth: 1
                                            )
                                    )
                            )
                        }
                        .hapticFeedback(.light)
                    }
            }
            .padding(.horizontal, 24)
                
                Spacer()
            }
            .frame(maxHeight: .infinity)
            .ignoresSafeArea(.container, edges: .bottom)
            .overlay(
                // Popup overlay
                Group {
                    if showPopup {
                        Color.black.opacity(0.5)
                            .ignoresSafeArea()
                            .onTapGesture {
                                UserDefaults.standard.set(true, forKey: "dietPopupShown")
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    showPopup = false
                                }
                            }
                        
                        // Popup content
                        VStack(spacing: 0) {
                            // Speech bubble arrow
                            Triangle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(
                                        stops: [
                                            .init(color: Color(red: 0.00, green: 0.57, blue: 0.27), location: 0.0),  // #009245
                                            .init(color: Color(red: 0.49, green: 0.75, blue: 0.20), location: 0.9), // #7EC033
                                            .init(color: Color(red: 0.99, green: 0.93, blue: 0.13), location: 1.0), // #FCEE21
                                        ]
                                        ),
                                        startPoint: .bottomLeading,
                                        endPoint: .topTrailing
                                    )
                                )
                                .frame(width: 20, height: 12)
                                .offset(y: 5)
                            
                            // Popup content
                            VStack(spacing: 16) {
                                Text("Tap to see how this habit impacts lifespan")
                                    .font(.system(size: 20, weight: .regular))
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.leading)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                Button(action: {
                                    UserDefaults.standard.set(true, forKey: "dietPopupShown")
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        showPopup = false
                                    }
                                }) {
                                    Text("Okay")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(Color("ampedGreen"))
                                        .padding(.horizontal, 24)
                                        .padding(.vertical, 12)
                                        .background(
                                            RoundedRectangle(cornerRadius: 20)
                                                .fill(Color.white)
                                        )
                                }
                            }
                            .padding(.horizontal, 24)
                            .padding(.vertical, 32)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(
                                         LinearGradient(
                                        gradient: Gradient(
                                        stops: [
                                           .init(color: Color(red: 0/255, green: 146/255, blue: 69/255), location: 0.0707),
                                            .init(color: Color(red: 63/255, green: 169/255, blue: 60/255), location: 0.291),
                                            .init(color: Color(red: 126/255, green: 192/255, blue: 51/255), location: 0.5908),
                                            .init(color: Color(red: 252/255, green: 238/255, blue: 33/255), location: 0.8026)
                                        ]
                                        ),
                                        startPoint: .bottomLeading,
                                        endPoint: .topTrailing
                                    )
                            )
                            )
                        }
                        .padding(.horizontal, 40)
                        .transition(.scale.combined(with: .opacity))
                    }
                }
            )
            .overlay(
                // Drawer overlay
                Group {
                    if showDrawer {
                        ZStack(alignment: .bottom) {
                            // Transparent background overlay
                            Color.clear
                                .ignoresSafeArea(.all)
                                .onTapGesture {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        showDrawer = false
                                    }
                                }
                            
                            // Drawer content - positioned at bottom
                            VStack(spacing: 0) {
                                // Handle bar (draggable)
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color.white)
                                    .frame(width: 40, height: 4)
                                    .padding(.top, 8)
                                    .padding(.bottom, 20)
                                    .onTapGesture {
                                        withAnimation(.easeInOut(duration: 0.3)) {
                                            showDrawer = false
                                        }
                                    }
                                
                                VStack(alignment: .leading, spacing: 20) {
                                    // Header
                                    HStack {
                                        Text("Impact score")
                                            .font(.system(size: 18, weight: .regular))
                                            .foregroundColor(.white)
                                        
                                        Spacer()
                                        
                                        Button(action: {
                                            withAnimation(.easeInOut(duration: 0.3)) {
                                                showDrawer = false
                                            }
                                        }) {
                                            Image(systemName: "xmark")
                                                .font(.system(size: 16, weight: .medium))
                                                .foregroundColor(.white)
                                        }
                                    }
                                    
                                    // Score display
                                    HStack(alignment: .bottom, spacing: 0) {
                                        Text("50")
                                            .font(.system(size: 48, weight: .bold))
                                            .foregroundColor(.white)
                                        
                                        Text("/100")
                                            .font(.system(size: 24, weight: .regular))
                                            .foregroundColor(.white)
                                            .padding(.bottom, 8)
                                    }
                                    
                                    // Slider
                                    VStack(alignment: .leading, spacing: 8) {
                                        // Custom slider
                                        GeometryReader { geometry in
                                            ZStack(alignment: .leading) {
                                                // Background track
                                                RoundedRectangle(cornerRadius: 4)
                                                    .fill(Color.white)
                                                    .frame(height: 8)
                                                
                                                // Progress track
                                                RoundedRectangle(cornerRadius: 4)
                                                    .fill(Color("ampedYellow"))
                                                    .frame(width: geometry.size.width * 0.5, height: 8)
                                                
                                                // Thumb
                                                Circle()
                                                    .fill(Color.gray)
                                                    .frame(width: 20, height: 20)
                                                    .offset(x: geometry.size.width * 0.5 - 10)
                                            }
                                        }
                                        .frame(height: 20)
                                        
                                        // Range labels
                                        HStack {
                                            Text("0")
                                                .font(.system(size: 12, weight: .regular))
                                                .foregroundColor(.gray)
                                            
                                            Spacer()
                                            
                                            Text("100")
                                                .font(.system(size: 12, weight: .regular))
                                                .foregroundColor(.gray)
                                        }
                                    }
                                    
                                    // Description text
                                    VStack(alignment: .leading, spacing: 12) {
                                        Text("This score estimates how your diet quality affects your life expectancy.")
                                            .font(.system(size: 16, weight: .regular))
                                            .foregroundColor(.white)
                                            .multilineTextAlignment(.leading)
                                        
                                        Text("Diet contributes to 25% of your total lifespan impact. It's important!")
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundColor(.white)
                                            .multilineTextAlignment(.leading)
                                        
                                        Text("Poor diet increases mortality risk by 35% compared to healthy eating patterns.")
                                            .font(.system(size: 14, weight: .regular))
                                            .foregroundColor(.white)
                                            .multilineTextAlignment(.leading)
                                    }
                                    
                                    // Source button
                                    Button(action: {
                                        // Handle source link tap
                                    }) {
                                        HStack {
                                            Text("Source: GBD 2019")
                                                .font(.system(size: 12, weight: .regular))
                                                .foregroundColor(.white)
                                            
                                            Image(systemName: "arrow.up.right")
                                                .font(.system(size: 12, weight: .regular))
                                                .foregroundColor(.white)
                                        }
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(Color.gray.opacity(0.3))
                                        )
                                    }
                                    .padding(.bottom, 20)
                                }
                                .padding(.horizontal, 24)
                            }
                            .background(
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .fill(Color(red: 0x27/255, green: 0x27/255, blue: 0x27/255)) // #272727
                            )
                            .ignoresSafeArea(.all)
                        }
                        .ignoresSafeArea(.all)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
            )
            .onAppear {
                // Show popup only once when view appears
                if !UserDefaults.standard.bool(forKey: "dietPopupShown") {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showPopup = true
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Smoking Question
    
    struct SmokingQuestionView: View {
        @ObservedObject var viewModel: QuestionnaireViewModel
        @Environment(\.adaptiveSpacing) private var spacing
        @State private var showPopup = false
        @State private var showDrawer = false
        
        var body: some View {
            VStack(alignment: .center, spacing: 0) {
                Spacer()
                
                // Emma character and question layout
                HStack(alignment: .top, spacing: 16) {
                    VStack(alignment: .leading, spacing: 12){
                        HStack(alignment: .center, spacing: 0){
                            // Emma character
                            Image("steptwo")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 68, height: 76)
                            
                            // Question text
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Do you smoke tobacco products?")
                                    .font(.system(size: 20, weight: .medium))
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.leading)
                                    .lineLimit(nil)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .frame(maxWidth: .infinity, alignment: .leading)

                            }
                        }
                        // Research citation with book icon
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showDrawer = true
                            }
                        }) {
                            HStack(spacing: 6) {
                                Image("book_ribbon")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 16, height: 16)
                                
                                Text("Tap to see what research based on 195 studies tell us.")
                                    .font(.system(size: 12, weight: .regular))
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    Spacer()
                }
                .padding(.horizontal, 24)
                
                Spacer()
                 .frame(maxHeight: 32)
                
                // Smoking status options
                VStack(spacing: 16) {
                    ForEach(QuestionnaireViewModel.SmokingStatus.allCases, id: \.self) { status in
                        Button(action: {
                            viewModel.selectedSmokingStatus = status
                            viewModel.proceedToNextQuestion()
                        }) {
                            VStack(alignment: .center, spacing: 4) {
                                Text(status.mainText)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                
                                if !status.subText.isEmpty {
                                    Text(status.subText)
                                        .font(.system(size: 14, weight: .regular))
                                        .foregroundColor(.gray)
                                        .frame(maxWidth: .infinity, alignment: .center)
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, status.subText.isEmpty ? 18 : 8)
                            .background(
                                RoundedRectangle(cornerRadius: 100)
                                    .fill(Color.black)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 100)
                                            .stroke(
                                                LinearGradient(
                                                    colors: [Color("ampedGreen"), Color("ampedYellow")],
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                ),
                                                lineWidth: 1
                                            )
                                    )
                            )
                        }
                        .hapticFeedback(.light)
                    }
            }
            .padding(.horizontal, 24)
                
                Spacer()
            }
            .frame(maxHeight: .infinity)
            .ignoresSafeArea(.container, edges: .bottom)
            .overlay(
                // Popup overlay
                Group {
                    if showPopup {
                        Color.black.opacity(0.5)
                            .ignoresSafeArea()
                            .onTapGesture {
                                UserDefaults.standard.set(true, forKey: "smokingPopupShown")
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    showPopup = false
                                }
                            }
                        
                        // Popup content
                        VStack(spacing: 0) {
                            // Speech bubble arrow
                            Triangle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(
                                        stops: [
                                            .init(color: Color(red: 0.00, green: 0.57, blue: 0.27), location: 0.0),  // #009245
                                            .init(color: Color(red: 0.49, green: 0.75, blue: 0.20), location: 0.9), // #7EC033
                                            .init(color: Color(red: 0.99, green: 0.93, blue: 0.13), location: 1.0), // #FCEE21
                                        ]
                                        ),
                                        startPoint: .bottomLeading,
                                        endPoint: .topTrailing
                                    )
                                )
                                .frame(width: 20, height: 12)
                                .offset(y: 5)
                            
                            // Popup content
                            VStack(spacing: 16) {
                                Text("Tap to see how this habit impacts lifespan")
                                    .font(.system(size: 20, weight: .regular))
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.leading)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                Button(action: {
                                    UserDefaults.standard.set(true, forKey: "smokingPopupShown")
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        showPopup = false
                                    }
                                }) {
                                    Text("Okay")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(Color("ampedGreen"))
                                        .padding(.horizontal, 24)
                                        .padding(.vertical, 12)
                                        .background(
                                            RoundedRectangle(cornerRadius: 20)
                                                .fill(Color.white)
                                        )
                                }
                            }
                            .padding(.horizontal, 24)
                            .padding(.vertical, 32)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(
                                         LinearGradient(
                                        gradient: Gradient(
                                        stops: [
                                           .init(color: Color(red: 0/255, green: 146/255, blue: 69/255), location: 0.0707),
                                            .init(color: Color(red: 63/255, green: 169/255, blue: 60/255), location: 0.291),
                                            .init(color: Color(red: 126/255, green: 192/255, blue: 51/255), location: 0.5908),
                                            .init(color: Color(red: 252/255, green: 238/255, blue: 33/255), location: 0.8026)
                                        ]
                                        ),
                                        startPoint: .bottomLeading,
                                        endPoint: .topTrailing
                                    )
                            )
                            )
                        }
                        .padding(.horizontal, 40)
                        .transition(.scale.combined(with: .opacity))
                    }
                }
            )
            .overlay(
                // Drawer overlay
                Group {
                    if showDrawer {
                        ZStack(alignment: .bottom) {
                            // Transparent background overlay
                            Color.clear
                                .ignoresSafeArea(.all)
                                .onTapGesture {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        showDrawer = false
                                    }
                                }
                            
                            // Drawer content - positioned at bottom
                            VStack(spacing: 0) {
                                // Handle bar (draggable)
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color.white)
                                    .frame(width: 40, height: 4)
                                    .padding(.top, 8)
                                    .padding(.bottom, 20)
                                    .onTapGesture {
                                        withAnimation(.easeInOut(duration: 0.3)) {
                                            showDrawer = false
                                        }
                                    }
                                
                                VStack(alignment: .leading, spacing: 20) {
                                    // Header
                                    HStack {
                                        Text("Impact score")
                                            .font(.system(size: 18, weight: .regular))
                                            .foregroundColor(.white)
                                        
                                        Spacer()
                                        
                                        Button(action: {
                                            withAnimation(.easeInOut(duration: 0.3)) {
                                                showDrawer = false
                                            }
                                        }) {
                                            Image(systemName: "xmark")
                                                .font(.system(size: 16, weight: .medium))
                                                .foregroundColor(.white)
                                        }
                                    }
                                    
                                    // Score display
                                    HStack(alignment: .bottom, spacing: 0) {
                                        Text("50")
                                            .font(.system(size: 48, weight: .bold))
                                            .foregroundColor(.white)
                                        
                                        Text("/100")
                                            .font(.system(size: 24, weight: .regular))
                                            .foregroundColor(.white)
                                            .padding(.bottom, 8)
                                    }
                                    
                                    // Slider
                                    VStack(alignment: .leading, spacing: 8) {
                                        // Custom slider
                                        GeometryReader { geometry in
                                            ZStack(alignment: .leading) {
                                                // Background track
                                                RoundedRectangle(cornerRadius: 4)
                                                    .fill(Color.white)
                                                    .frame(height: 8)
                                                
                                                // Progress track
                                                RoundedRectangle(cornerRadius: 4)
                                                    .fill(Color("ampedYellow"))
                                                    .frame(width: geometry.size.width * 0.5, height: 8)
                                                
                                                // Thumb
                                                Circle()
                                                    .fill(Color.gray)
                                                    .frame(width: 20, height: 20)
                                                    .offset(x: geometry.size.width * 0.5 - 10)
                                            }
                                        }
                                        .frame(height: 20)
                                        
                                        // Range labels
                                        HStack {
                                            Text("0")
                                                .font(.system(size: 12, weight: .regular))
                                                .foregroundColor(.gray)
                                            
                                            Spacer()
                                            
                                            Text("100")
                                                .font(.system(size: 12, weight: .regular))
                                                .foregroundColor(.gray)
                                        }
                                    }
                                    
                                    // Description text
                                    VStack(alignment: .leading, spacing: 12) {
                                        Text("This score estimates how your smoking habits affect your life expectancy.")
                                            .font(.system(size: 16, weight: .regular))
                                            .foregroundColor(.white)
                                            .multilineTextAlignment(.leading)
                                        
                                        Text("Smoking contributes to 40% of your total lifespan impact. It's critical!")
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundColor(.white)
                                            .multilineTextAlignment(.leading)
                                        
                                        Text("Daily smoking reduces life expectancy by 10-15 years compared to non-smokers.")
                                            .font(.system(size: 14, weight: .regular))
                                            .foregroundColor(.white)
                                            .multilineTextAlignment(.leading)
                                    }
                                    
                                    // Source button
                                    Button(action: {
                                        // Handle source link tap
                                    }) {
                                        HStack {
                                            Text("Source: CDC 2023")
                                                .font(.system(size: 12, weight: .regular))
                                                .foregroundColor(.white)
                                            
                                            Image(systemName: "arrow.up.right")
                                                .font(.system(size: 12, weight: .regular))
                                                .foregroundColor(.white)
                                        }
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(Color.gray.opacity(0.3))
                                        )
                                    }
                                    .padding(.bottom, 20)
                                }
                                .padding(.horizontal, 24)
                            }
                            .background(
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .fill(Color(red: 0x27/255, green: 0x27/255, blue: 0x27/255)) // #272727
                            )
                            .ignoresSafeArea(.all)
                        }
                        .ignoresSafeArea(.all)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
            )
            .onAppear {
                // Show popup only once when view appears
                if !UserDefaults.standard.bool(forKey: "smokingPopupShown") {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showPopup = true
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Alcohol Question
    
    struct AlcoholQuestionView: View {
        @ObservedObject var viewModel: QuestionnaireViewModel
        @Environment(\.adaptiveSpacing) private var spacing
        @State private var showPopup = false
        @State private var showDrawer = false
        
        var body: some View {
            VStack(alignment: .center, spacing: 0) {
                Spacer()
                
                // Emma character and question layout
                HStack(alignment: .top, spacing: 16) {
                    VStack(alignment: .leading, spacing: 12){
                        HStack(alignment: .center, spacing: 0){
                            // Emma character
                            Image("steptwo")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 68, height: 76)
                            
                            // Question text
                            VStack(alignment: .leading, spacing: 8) {
                                Text("How often do you consume alcoholic beverages?")
                                    .font(.system(size: 20, weight: .medium))
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.leading)
                                    .lineLimit(nil)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .frame(maxWidth: .infinity, alignment: .leading)

                            }
                        }
                        // Research citation with book icon
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showDrawer = true
                            }
                        }) {
                            HStack(spacing: 6) {
                                Image("book_ribbon")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 16, height: 16)
                                
                                Text("Tap to see what research based on 195 studies tell us.")
                                    .font(.system(size: 12, weight: .regular))
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    Spacer()
                }
                .padding(.horizontal, 24)
                
                Spacer()
                 .frame(maxHeight: 32)
                
                // Alcohol frequency options
                VStack(spacing: 16) {
                    ForEach(QuestionnaireViewModel.AlcoholFrequency.allCases, id: \.self) { frequency in
                        Button(action: {
                            viewModel.selectedAlcoholFrequency = frequency
                            viewModel.proceedToNextQuestion()
                        }) {
                            VStack(alignment: .center, spacing: 4) {
                                Text(frequency.mainText)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity, alignment: .center)

                                if !frequency.subText.isEmpty {
                                    Text(frequency.subText)
                                        .font(.system(size: 14, weight: .regular))
                                        .foregroundColor(.gray)
                                        .frame(maxWidth: .infinity, alignment: .center)
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, frequency.subText.isEmpty ? 18 : 8)
                            .background(
                                RoundedRectangle(cornerRadius: 100)
                                    .fill(Color.black)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 100)
                                            .stroke(
                                                LinearGradient(
                                                    colors: [Color("ampedGreen"), Color("ampedYellow")],
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                ),
                                                lineWidth: 1
                                            )
                                    )
                            )
                        }
                        .hapticFeedback(.light)
                    }
                }
                .padding(.horizontal, 24)

                Spacer()
            }
            .frame(maxHeight: .infinity)
            .ignoresSafeArea(.container, edges: .bottom)
            .overlay(
                // Popup overlay
                Group {
                    if showPopup {
                        Color.black.opacity(0.5)
                            .ignoresSafeArea()
                            .onTapGesture {
                                UserDefaults.standard.set(true, forKey: "alcoholPopupShown")
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    showPopup = false
                                }
                            }

                        VStack(spacing: 0) {
                            Triangle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(
                                        stops: [
                                            .init(color: Color(red: 0.00, green: 0.57, blue: 0.27), location: 0.0),
                                            .init(color: Color(red: 0.49, green: 0.75, blue: 0.20), location: 0.9),
                                            .init(color: Color(red: 0.99, green: 0.93, blue: 0.13), location: 1.0),
                                        ]
                                        ),
                                        startPoint: .bottomLeading,
                                        endPoint: .topTrailing
                                    )
                                )
                                .frame(width: 20, height: 12)
                                .offset(y: 5)

                            VStack(spacing: 16) {
                                Text("Tap to see how this habit impacts lifespan")
                                    .font(.system(size: 20, weight: .regular))
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.leading)
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                Button(action: {
                                    UserDefaults.standard.set(true, forKey: "alcoholPopupShown")
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        showPopup = false
                                    }
                                }) {
                                    Text("Okay")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(Color("ampedGreen"))
                                        .padding(.horizontal, 24)
                                        .padding(.vertical, 12)
                                        .background(
                                            RoundedRectangle(cornerRadius: 20)
                                                .fill(Color.white)
                                        )
                                }
                            }
                            .padding(.horizontal, 24)
                            .padding(.vertical, 32)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(
                                         LinearGradient(
                                        gradient: Gradient(
                                        stops: [
                                           .init(color: Color(red: 0/255, green: 146/255, blue: 69/255), location: 0.0707),
                                            .init(color: Color(red: 63/255, green: 169/255, blue: 60/255), location: 0.291),
                                            .init(color: Color(red: 126/255, green: 192/255, blue: 51/255), location: 0.5908),
                                            .init(color: Color(red: 252/255, green: 238/255, blue: 33/255), location: 0.8026)
                                        ]
                                        ),
                                        startPoint: .bottomLeading,
                                        endPoint: .topTrailing
                                    )
                            )
                            )
                        }
                        .padding(.horizontal, 40)
                        .transition(.scale.combined(with: .opacity))
                    }
                }
            )
            .overlay(
                // Drawer overlay
                Group {
                    if showDrawer {
                        ZStack(alignment: .bottom) {
                            Color.clear
                                .ignoresSafeArea(.all)
                                .onTapGesture {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        showDrawer = false
                                    }
                                }

                            VStack(spacing: 0) {
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color.white)
                                    .frame(width: 40, height: 4)
                                    .padding(.top, 8)
                                    .padding(.bottom, 20)
                                    .onTapGesture {
                                        withAnimation(.easeInOut(duration: 0.3)) {
                                            showDrawer = false
                                        }
                                    }

                                VStack(alignment: .leading, spacing: 20) {
                                    HStack {
                                        Text("Impact score")
                                            .font(.system(size: 18, weight: .regular))
                                            .foregroundColor(.white)
                                        Spacer()
                                        Button(action: {
                                            withAnimation(.easeInOut(duration: 0.3)) {
                                                showDrawer = false
                                            }
                                        }) {
                                            Image(systemName: "xmark")
                                                .font(.system(size: 16, weight: .medium))
                                                .foregroundColor(.white)
                                        }
                                    }

                                    HStack(alignment: .bottom, spacing: 0) {
                                        Text("50")
                                            .font(.system(size: 48, weight: .bold))
                                            .foregroundColor(.white)
                                        Text("/100")
                                            .font(.system(size: 24, weight: .regular))
                                            .foregroundColor(.white)
                                            .padding(.bottom, 8)
                                    }

                                    VStack(alignment: .leading, spacing: 8) {
                                        GeometryReader { geometry in
                                            ZStack(alignment: .leading) {
                                                RoundedRectangle(cornerRadius: 4)
                                                    .fill(Color.white)
                                                    .frame(height: 8)
                                                RoundedRectangle(cornerRadius: 4)
                                                    .fill(Color("ampedYellow"))
                                                    .frame(width: geometry.size.width * 0.5, height: 8)
                                                Circle()
                                                    .fill(Color.gray)
                                                    .frame(width: 20, height: 20)
                                                    .offset(x: geometry.size.width * 0.5 - 10)
                                            }
                                        }
                                        .frame(height: 20)

                                        HStack {
                                            Text("0")
                                                .font(.system(size: 12, weight: .regular))
                                                .foregroundColor(.gray)
                                            Spacer()
                                            Text("100")
                                                .font(.system(size: 12, weight: .regular))
                                                .foregroundColor(.gray)
                                        }
                                    }

                                    VStack(alignment: .leading, spacing: 12) {
                                        Text("This score estimates how your alcohol consumption affects your life expectancy.")
                                            .font(.system(size: 16, weight: .regular))
                                            .foregroundColor(.white)
                                            .multilineTextAlignment(.leading)
                                        Text("Alcohol contributes to 15% of your total lifespan impact. It's significant!")
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundColor(.white)
                                            .multilineTextAlignment(.leading)
                                        Text("Heavy drinking reduces life expectancy by 4-5 years compared to moderate consumption.")
                                            .font(.system(size: 14, weight: .regular))
                                            .foregroundColor(.white)
                                            .multilineTextAlignment(.leading)
                                    }

                                    Button(action: { /* Handle source link tap */ }) {
                                        HStack {
                                            Text("Source: WHO 2023")
                                                .font(.system(size: 12, weight: .regular))
                                                .foregroundColor(.white)
                                            Image(systemName: "arrow.up.right")
                                                .font(.system(size: 12, weight: .regular))
                                                .foregroundColor(.white)
                                        }
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(Color.gray.opacity(0.3))
                                        )
                                    }
                                    .padding(.bottom, 20)
                                }
                                .padding(.horizontal, 24)
                            }
                            .background(
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .fill(Color(red: 0x27/255, green: 0x27/255, blue: 0x27/255)) // #272727
                            )
                            .ignoresSafeArea(.all)
                        }
                        .ignoresSafeArea(.all)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
            )
            .onAppear {
                if !UserDefaults.standard.bool(forKey: "alcoholPopupShown") {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showPopup = true
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Social Connections Question
    
    struct SocialConnectionsQuestionView: View {
        @ObservedObject var viewModel: QuestionnaireViewModel
        @Environment(\.adaptiveSpacing) private var spacing
        @State private var showPopup = false
        @State private var showDrawer = false
        
        var body: some View {
            VStack(alignment: .center, spacing: 0) {
                Spacer()
                
                // Emma character and question layout
                HStack(alignment: .top, spacing: 16) {
                    VStack(alignment: .leading, spacing: 12){
                        HStack(alignment: .center, spacing: 0){
                            // Emma character
                            Image("steptwo")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 68, height: 76)
                            
                            // Question text
                            VStack(alignment: .leading, spacing: 8) {
                                Text("How would you describe your social connections?")
                                    .font(.system(size: 20, weight: .medium))
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.leading)
                                    .lineLimit(nil)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .frame(maxWidth: .infinity, alignment: .leading)

                            }
                        }
                        // Research citation with book icon
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showDrawer = true
                            }
                        }) {
                            HStack(spacing: 6) {
                                Image("book_ribbon")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 16, height: 16)
                                
                                Text("Tap to see what research based on 195 studies tell us.")
                                    .font(.system(size: 12, weight: .regular))
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    Spacer()
                }
                .padding(.horizontal, 24)
                
                Spacer()
                 .frame(maxHeight: 32)
                
                // Social connections quality options
                VStack(spacing: 16) {
                    ForEach(QuestionnaireViewModel.SocialConnectionsQuality.allCases, id: \.self) { quality in
                        Button(action: {
                            viewModel.selectedSocialConnectionsQuality = quality
                            viewModel.proceedToNextQuestion()
                        }) {
                            VStack(alignment: .center, spacing: 4) {
                                Text(quality.mainText)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity, alignment: .center)

                                if !quality.subText.isEmpty {
                                    Text(quality.subText)
                                        .font(.system(size: 14, weight: .regular))
                                        .foregroundColor(.gray)
                                        .frame(maxWidth: .infinity, alignment: .center)
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, quality.subText.isEmpty ? 18 : 8)
                            .background(
                                RoundedRectangle(cornerRadius: 100)
                                    .fill(Color.black)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 100)
                                            .stroke(
                                                LinearGradient(
                                                    colors: [Color("ampedGreen"), Color("ampedYellow")],
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                ),
                                                lineWidth: 1
                                            )
                                    )
                            )
                        }
                        .hapticFeedback(.light)
                    }
                }
                .padding(.horizontal, 24)

                Spacer()
            }
            .frame(maxHeight: .infinity)
            .ignoresSafeArea(.container, edges: .bottom)
            .overlay(
                // Popup overlay
                Group {
                    if showPopup {
                        Color.black.opacity(0.5)
                            .ignoresSafeArea()
                            .onTapGesture {
                                UserDefaults.standard.set(true, forKey: "socialConnectionsPopupShown")
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    showPopup = false
                                }
                            }

                        VStack(spacing: 0) {
                            Triangle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(
                                        stops: [
                                            .init(color: Color(red: 0.00, green: 0.57, blue: 0.27), location: 0.0),
                                            .init(color: Color(red: 0.49, green: 0.75, blue: 0.20), location: 0.9),
                                            .init(color: Color(red: 0.99, green: 0.93, blue: 0.13), location: 1.0),
                                        ]
                                        ),
                                        startPoint: .bottomLeading,
                                        endPoint: .topTrailing
                                    )
                                )
                                .frame(width: 20, height: 12)
                                .offset(y: 5)

                            VStack(spacing: 16) {
                                Text("Tap to see how this habit impacts lifespan")
                                    .font(.system(size: 20, weight: .regular))
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.leading)
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                Button(action: {
                                    UserDefaults.standard.set(true, forKey: "socialConnectionsPopupShown")
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        showPopup = false
                                    }
                                }) {
                                    Text("Okay")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(Color("ampedGreen"))
                                        .padding(.horizontal, 24)
                                        .padding(.vertical, 12)
                                        .background(
                                            RoundedRectangle(cornerRadius: 20)
                                                .fill(Color.white)
                                        )
                                }
                            }
                            .padding(.horizontal, 24)
                            .padding(.vertical, 32)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(
                                         LinearGradient(
                                        gradient: Gradient(
                                        stops: [
                                           .init(color: Color(red: 0/255, green: 146/255, blue: 69/255), location: 0.0707),
                                            .init(color: Color(red: 63/255, green: 169/255, blue: 60/255), location: 0.291),
                                            .init(color: Color(red: 126/255, green: 192/255, blue: 51/255), location: 0.5908),
                                            .init(color: Color(red: 252/255, green: 238/255, blue: 33/255), location: 0.8026)
                                        ]
                                        ),
                                        startPoint: .bottomLeading,
                                        endPoint: .topTrailing
                                    )
                            )
                            )
                        }
                        .padding(.horizontal, 40)
                        .transition(.scale.combined(with: .opacity))
                    }
                }
            )
            .overlay(
                // Drawer overlay
                Group {
                    if showDrawer {
                        ZStack(alignment: .bottom) {
                            Color.clear
                                .ignoresSafeArea(.all)
                                .onTapGesture {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        showDrawer = false
                                    }
                                }

                            VStack(spacing: 0) {
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color.white)
                                    .frame(width: 40, height: 4)
                                    .padding(.top, 8)
                                    .padding(.bottom, 20)
                                    .onTapGesture {
                                        withAnimation(.easeInOut(duration: 0.3)) {
                                            showDrawer = false
                                        }
                                    }

                                VStack(alignment: .leading, spacing: 20) {
                                    HStack {
                                        Text("Impact score")
                                            .font(.system(size: 18, weight: .regular))
                                            .foregroundColor(.white)
                                        Spacer()
                                        Button(action: {
                                            withAnimation(.easeInOut(duration: 0.3)) {
                                                showDrawer = false
                                            }
                                        }) {
                                            Image(systemName: "xmark")
                                                .font(.system(size: 16, weight: .medium))
                                                .foregroundColor(.white)
                                        }
                                    }

                                    HStack(alignment: .bottom, spacing: 0) {
                                        Text("50")
                                            .font(.system(size: 48, weight: .bold))
                                            .foregroundColor(.white)
                                        Text("/100")
                                            .font(.system(size: 24, weight: .regular))
                                            .foregroundColor(.white)
                                            .padding(.bottom, 8)
                                    }

                                    VStack(alignment: .leading, spacing: 8) {
                                        GeometryReader { geometry in
                                            ZStack(alignment: .leading) {
                                                RoundedRectangle(cornerRadius: 4)
                                                    .fill(Color.white)
                                                    .frame(height: 8)
                                                RoundedRectangle(cornerRadius: 4)
                                                    .fill(Color("ampedYellow"))
                                                    .frame(width: geometry.size.width * 0.5, height: 8)
                                                Circle()
                                                    .fill(Color.gray)
                                                    .frame(width: 20, height: 20)
                                                    .offset(x: geometry.size.width * 0.5 - 10)
                                            }
                                        }
                                        .frame(height: 20)

                                        HStack {
                                            Text("0")
                                                .font(.system(size: 12, weight: .regular))
                                                .foregroundColor(.gray)
                                            Spacer()
                                            Text("100")
                                                .font(.system(size: 12, weight: .regular))
                                                .foregroundColor(.gray)
                                        }
                                    }

                                    VStack(alignment: .leading, spacing: 12) {
                                        Text("This score estimates how your social connections affect your life expectancy.")
                                            .font(.system(size: 16, weight: .regular))
                                            .foregroundColor(.white)
                                            .multilineTextAlignment(.leading)
                                        Text("Social connections contribute to 20% of your total lifespan impact. It's important!")
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundColor(.white)
                                            .multilineTextAlignment(.leading)
                                        Text("Strong social connections can increase life expectancy by 2-3 years compared to isolation.")
                                            .font(.system(size: 14, weight: .regular))
                                            .foregroundColor(.white)
                                            .multilineTextAlignment(.leading)
                                    }

                                    Button(action: { /* Handle source link tap */ }) {
                                        HStack {
                                            Text("Source: Harvard Study 2023")
                                                .font(.system(size: 12, weight: .regular))
                                                .foregroundColor(.white)
                                            Image(systemName: "arrow.up.right")
                                                .font(.system(size: 12, weight: .regular))
                                                .foregroundColor(.white)
                                        }
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(Color.gray.opacity(0.3))
                                        )
                                    }
                                    .padding(.bottom, 20)
                                }
                                .padding(.horizontal, 24)
                            }
                            .background(
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .fill(Color(red: 0x27/255, green: 0x27/255, blue: 0x27/255)) // #272727
                            )
                            .ignoresSafeArea(.all)
                        }
                        .ignoresSafeArea(.all)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
            )
            .onAppear {
                if !UserDefaults.standard.bool(forKey: "socialConnectionsPopupShown") {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showPopup = true
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Desired Daily Lifespan Gain Question (replaces sleep duration dial)
    struct SleepQualityQuestionView: View {
        @ObservedObject var viewModel: QuestionnaireViewModel
        @State private var desiredMinutes: Int = 10 // 5..120
        @Environment(\.adaptiveSpacing) private var spacing
        @State private var showDrawer = false

        var body: some View {
            VStack(alignment: .center, spacing: 0) {
                Spacer()
                
                // Emma character and question layout
                HStack(alignment: .top, spacing: 16) {
                    VStack(alignment: .leading, spacing: 12){
                        HStack(alignment: .center, spacing: 0){
                            // Emma character
                            Image("steptwo")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 68, height: 76)
                            
                            // Question text
                            VStack(alignment: .leading, spacing: 0) {
                                Text("Let's set some goals.")
                                    .font(.system(size: 20, weight: .medium))
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.leading)
                                    .lineLimit(nil)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                Text("Please choose number of hours you want to add on daily basis.")
                                .font(.system(size: 16, weight: .regular))
                                .foregroundColor(.white.opacity(0.8))

                            }
                        }
                    }
                    Spacer()
                }
                .padding(.leading, 24)
                
                Spacer()
                 .frame(maxHeight: 63)
                
                // Circular slider/dial
                VStack(spacing: 20) {
                    // Circular dial
                    ZStack {
                        // Background circle with bigger stroke
                        Circle()
                            .stroke(Color.white, lineWidth: 12)
                            .frame(width: 200, height: 200)
                        
                        // Progress arc with rounder edges
                        Circle()
                            .trim(from: 0, to: CGFloat(desiredMinutes) / 120.0)
                            .stroke(
                                LinearGradient(
                                    colors: [Color("ampedGreen"), Color("ampedYellow")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ),
                                style: StrokeStyle(lineWidth: 12, lineCap: .round)
                            )
                            .frame(width: 200, height: 200)
                            .rotationEffect(.degrees(-90))
                        
                        // White circle at the end of progress arc
                        Circle()
                            .fill(Color.white)
                            .frame(width: 16, height: 16)
                            .offset(
                                x: sin(Double(desiredMinutes) * 3.0 * .pi / 180) * 100,
                                y: -cos(Double(desiredMinutes) * 3.0 * .pi / 180) * 100
                            )
                        
                        // Center content
                        VStack(spacing: 8) {
                            Image("batteryIcon")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 32, height: 32)
                            
                            Text("\(desiredMinutes) Mins")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                        }
                    }
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                let angle = atan2(value.location.y - 100, value.location.x - 100)
                                let degrees = angle * 180 / .pi
                                let normalizedDegrees = (degrees + 90 + 360).truncatingRemainder(dividingBy: 360)
                                let minutes = Int(normalizedDegrees / 3.0)
                                desiredMinutes = max(5, min(120, minutes))
                            }
                    )
                    
                    Spacer()
                 .frame(maxHeight: 32)
                 
                    // Research citation with book icon - moved below progress
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showDrawer = true
                        }
                    }) {
                        HStack(spacing: 6) {
                            Image("book_ribbon")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 16, height: 16)
                            
                            Text("Backed by 500+ studies, 15+ million participants")
                                .font(.system(size: 12, weight: .regular))
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(.horizontal, 24)

                Spacer()
                 .frame(maxHeight: 32)
                
                // Continue button
                Button(action: {
                    viewModel.desiredDailyLifespanGainMinutes = desiredMinutes
                    // Map the user's aspiration to sleep quality preference proxy for compatibility
                    viewModel.selectedSleepQuality = mapDesiredGainToSleepQuality(desiredMinutes)
                    
                    // Setup smart goal-based notifications for this user's target
                    NotificationManager.shared.scheduleGoalBasedNotifications(targetMinutes: desiredMinutes)
                    
                    // Proceed to next question (deviceTracking)
                    viewModel.proceedToNextQuestion()
                }) {
                    Text("Continue")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [Color("ampedGreen"), Color("ampedYellow")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(25)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 20)

                Spacer()
            }
            .frame(maxHeight: .infinity)
            .ignoresSafeArea(.container, edges: .bottom)
            .overlay(
                // Drawer overlay
                Group {
                    if showDrawer {
                        ZStack(alignment: .bottom) {
                            Color.clear
                                .ignoresSafeArea(.all)
                                .onTapGesture {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        showDrawer = false
                                    }
                                }

                            VStack(spacing: 0) {
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color.white)
                                    .frame(width: 40, height: 4)
                                    .padding(.top, 8)
                                    .padding(.bottom, 20)
                                    .onTapGesture {
                                        withAnimation(.easeInOut(duration: 0.3)) {
                                            showDrawer = false
                                        }
                                    }

                                VStack(alignment: .leading, spacing: 20) {
                                    HStack {
                                        Text("Impact score")
                                            .font(.system(size: 18, weight: .regular))
                                            .foregroundColor(.white)
                                        Spacer()
                                        Button(action: {
                                            withAnimation(.easeInOut(duration: 0.3)) {
                                                showDrawer = false
                                            }
                                        }) {
                                            Image(systemName: "xmark")
                                                .font(.system(size: 16, weight: .medium))
                                                .foregroundColor(.white)
                                        }
                                    }

                                    HStack(alignment: .bottom, spacing: 0) {
                                        Text("50")
                                            .font(.system(size: 48, weight: .bold))
                                            .foregroundColor(.white)
                                        Text("/100")
                                            .font(.system(size: 24, weight: .regular))
                                            .foregroundColor(.white)
                                            .padding(.bottom, 8)
                                    }

                                    VStack(alignment: .leading, spacing: 8) {
                                        GeometryReader { geometry in
                                            ZStack(alignment: .leading) {
                                                RoundedRectangle(cornerRadius: 4)
                                                    .fill(Color.white)
                                                    .frame(height: 8)
                                                RoundedRectangle(cornerRadius: 4)
                                                    .fill(Color("ampedYellow"))
                                                    .frame(width: geometry.size.width * 0.5, height: 8)
                                                Circle()
                                                    .fill(Color.gray)
                                                    .frame(width: 20, height: 20)
                                                    .offset(x: geometry.size.width * 0.5 - 10)
                                            }
                                        }
                                        .frame(height: 20)

                                        HStack {
                                            Text("0")
                                                .font(.system(size: 12, weight: .regular))
                                                .foregroundColor(.gray)
                                            Spacer()
                                            Text("100")
                                                .font(.system(size: 12, weight: .regular))
                                                .foregroundColor(.gray)
                                        }
                                    }

                                    VStack(alignment: .leading, spacing: 12) {
                                        Text("This score estimates how your sleep quality affects your life expectancy.")
                                            .font(.system(size: 16, weight: .regular))
                                            .foregroundColor(.white)
                                            .multilineTextAlignment(.leading)
                                        Text("Sleep quality contributes to 30% of your total lifespan impact. It's crucial!")
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundColor(.white)
                                            .multilineTextAlignment(.leading)
                                        Text("Poor sleep quality can reduce life expectancy by 6-8 years compared to excellent sleep.")
                                            .font(.system(size: 14, weight: .regular))
                                            .foregroundColor(.white)
                                            .multilineTextAlignment(.leading)
                                    }

                                    Button(action: { /* Handle source link tap */ }) {
                                        HStack {
                                            Text("Source: Sleep Foundation 2023")
                                                .font(.system(size: 12, weight: .regular))
                                                .foregroundColor(.white)
                                            Image(systemName: "arrow.up.right")
                                                .font(.system(size: 12, weight: .regular))
                                                .foregroundColor(.white)
                                        }
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(Color.gray.opacity(0.3))
                                        )
                                    }
                                    .padding(.bottom, 20)
                                }
                                .padding(.horizontal, 24)
                            }
                            .background(
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .fill(Color(red: 0x27/255, green: 0x27/255, blue: 0x27/255)) // #272727
                            )
                            .ignoresSafeArea(.all)
                        }
                        .ignoresSafeArea(.all)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
            )
        }

        private func mapDesiredGainToSleepQuality(_ minutes: Int) -> QuestionnaireViewModel.SleepQuality {
            // Coarse mapping only to satisfy existing validation logic without changing downstream types
            switch minutes {
            case ..<20: return .average
            case 20..<40: return .good
            case 40...: return .excellent
            default: return .average
            }
        }
    }
    
    // MARK: - Blood Pressure Awareness Question
    struct BloodPressureAwarenessQuestionView: View {
        @ObservedObject var viewModel: QuestionnaireViewModel
        @Environment(\.adaptiveSpacing) private var spacing
        @State private var showPopup = false
        @State private var showDrawer = false

        var body: some View {
            VStack(alignment: .center, spacing: 0) {
                Spacer()
                
                // Emma character and question layout
                HStack(alignment: .top, spacing: 16) {
                    VStack(alignment: .leading, spacing: 12){
                        HStack(alignment: .center, spacing: 0){
                            // Emma character
                            Image("steptwo")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 68, height: 76)
                            
                            // Question text
                            VStack(alignment: .leading, spacing: 8) {
                                Text("What is your typical blood pressure reading?")
                                    .font(.system(size: 20, weight: .medium))
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.leading)
                                    .lineLimit(nil)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .frame(maxWidth: .infinity, alignment: .leading)

                            }
                        }
                        // Research citation with book icon
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showDrawer = true
                            }
                        }) {
                            HStack(spacing: 6) {
                                Image("book_ribbon")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 16, height: 16)
                                
                                Text("Tap to see what research based on 195 studies tell us.")
                                    .font(.system(size: 12, weight: .regular))
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    Spacer()
                }
                .padding(.horizontal, 24)
                
                Spacer()
                 .frame(maxHeight: 32)
                
                // Blood pressure category options
                VStack(spacing: 16) {
                    ForEach(QuestionnaireViewModel.BloodPressureCategory.allCases, id: \.self) { category in
                        Button(action: {
                            viewModel.selectedBloodPressureCategory = category
                            viewModel.proceedToNextQuestion()
                        }) {
                            VStack(alignment: .center, spacing: 4) {
                                Text(category.mainText)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity, alignment: .center)

                                if !category.subText.isEmpty {
                                    Text(category.subText)
                                        .font(.system(size: 14, weight: .regular))
                                        .foregroundColor(.gray)
                                        .frame(maxWidth: .infinity, alignment: .center)
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, category.subText.isEmpty ? 18 : 8)
                            .background(
                                RoundedRectangle(cornerRadius: 100)
                                    .fill(Color.black)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 100)
                                            .stroke(
                                                LinearGradient(
                                                    colors: [Color("ampedGreen"), Color("ampedYellow")],
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                ),
                                                lineWidth: 1
                                            )
                                    )
                            )
                        }
                        .hapticFeedback(.light)
                    }
                }
                .padding(.horizontal, 24)

                Spacer()
            }
            .frame(maxHeight: .infinity)
            .ignoresSafeArea(.container, edges: .bottom)
            .overlay(
                // Popup overlay
                Group {
                    if showPopup {
                        Color.black.opacity(0.5)
                            .ignoresSafeArea()
                            .onTapGesture {
                                UserDefaults.standard.set(true, forKey: "bloodPressurePopupShown")
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    showPopup = false
                                }
                            }

                        VStack(spacing: 0) {
                            Triangle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(
                                        stops: [
                                            .init(color: Color(red: 0.00, green: 0.57, blue: 0.27), location: 0.0),
                                            .init(color: Color(red: 0.49, green: 0.75, blue: 0.20), location: 0.9),
                                            .init(color: Color(red: 0.99, green: 0.93, blue: 0.13), location: 1.0),
                                        ]
                                        ),
                                        startPoint: .bottomLeading,
                                        endPoint: .topTrailing
                                    )
                                )
                                .frame(width: 20, height: 12)
                                .offset(y: 5)

                            VStack(spacing: 16) {
                                Text("Tap to see how this habit impacts lifespan")
                                    .font(.system(size: 20, weight: .regular))
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.leading)
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                Button(action: {
                                    UserDefaults.standard.set(true, forKey: "bloodPressurePopupShown")
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        showPopup = false
                                    }
                                }) {
                                    Text("Okay")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(Color("ampedGreen"))
                                        .padding(.horizontal, 24)
                                        .padding(.vertical, 12)
                                        .background(
                                            RoundedRectangle(cornerRadius: 20)
                                                .fill(Color.white)
                                        )
                                }
                            }
                            .padding(.horizontal, 24)
                            .padding(.vertical, 32)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(
                                         LinearGradient(
                                        gradient: Gradient(
                                        stops: [
                                           .init(color: Color(red: 0/255, green: 146/255, blue: 69/255), location: 0.0707),
                                            .init(color: Color(red: 63/255, green: 169/255, blue: 60/255), location: 0.291),
                                            .init(color: Color(red: 126/255, green: 192/255, blue: 51/255), location: 0.5908),
                                            .init(color: Color(red: 252/255, green: 238/255, blue: 33/255), location: 0.8026)
                                        ]
                                        ),
                                        startPoint: .bottomLeading,
                                        endPoint: .topTrailing
                                    )
                            )
                            )
                        }
                        .padding(.horizontal, 40)
                        .transition(.scale.combined(with: .opacity))
                    }
                }
            )
            .overlay(
                // Drawer overlay
                Group {
                    if showDrawer {
                        ZStack(alignment: .bottom) {
                            Color.clear
                                .ignoresSafeArea(.all)
                                .onTapGesture {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        showDrawer = false
                                    }
                                }

                            VStack(spacing: 0) {
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color.white)
                                    .frame(width: 40, height: 4)
                                    .padding(.top, 8)
                                    .padding(.bottom, 20)
                                    .onTapGesture {
                                        withAnimation(.easeInOut(duration: 0.3)) {
                                            showDrawer = false
                                        }
                                    }

                                VStack(alignment: .leading, spacing: 20) {
                                    HStack {
                                        Text("Impact score")
                                            .font(.system(size: 18, weight: .regular))
                                            .foregroundColor(.white)
                                        Spacer()
                                        Button(action: {
                                            withAnimation(.easeInOut(duration: 0.3)) {
                                                showDrawer = false
                                            }
                                        }) {
                                            Image(systemName: "xmark")
                                                .font(.system(size: 16, weight: .medium))
                                                .foregroundColor(.white)
                                        }
                                    }

                                    HStack(alignment: .bottom, spacing: 0) {
                                        Text("50")
                                            .font(.system(size: 48, weight: .bold))
                                            .foregroundColor(.white)
                                        Text("/100")
                                            .font(.system(size: 24, weight: .regular))
                                            .foregroundColor(.white)
                                            .padding(.bottom, 8)
                                    }

                                    VStack(alignment: .leading, spacing: 8) {
                                        GeometryReader { geometry in
                                            ZStack(alignment: .leading) {
                                                RoundedRectangle(cornerRadius: 4)
                                                    .fill(Color.white)
                                                    .frame(height: 8)
                                                RoundedRectangle(cornerRadius: 4)
                                                    .fill(Color("ampedYellow"))
                                                    .frame(width: geometry.size.width * 0.5, height: 8)
                                                Circle()
                                                    .fill(Color.gray)
                                                    .frame(width: 20, height: 20)
                                                    .offset(x: geometry.size.width * 0.5 - 10)
                                            }
                                        }
                                        .frame(height: 20)

                                        HStack {
                                            Text("0")
                                                .font(.system(size: 12, weight: .regular))
                                                .foregroundColor(.gray)
                                            Spacer()
                                            Text("100")
                                                .font(.system(size: 12, weight: .regular))
                                                .foregroundColor(.gray)
                                        }
                                    }

                                    VStack(alignment: .leading, spacing: 12) {
                                        Text("This score estimates how your blood pressure affects your life expectancy.")
                                            .font(.system(size: 16, weight: .regular))
                                            .foregroundColor(.white)
                                            .multilineTextAlignment(.leading)
                                        Text("Blood pressure contributes to 25% of your total lifespan impact. It's critical!")
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundColor(.white)
                                            .multilineTextAlignment(.leading)
                                        Text("High blood pressure can reduce life expectancy by 5-7 years compared to normal readings.")
                                            .font(.system(size: 14, weight: .regular))
                                            .foregroundColor(.white)
                                            .multilineTextAlignment(.leading)
                                    }

                                    Button(action: { /* Handle source link tap */ }) {
                                        HStack {
                                            Text("Source: AHA 2023")
                                                .font(.system(size: 12, weight: .regular))
                                                .foregroundColor(.white)
                                            Image(systemName: "arrow.up.right")
                                                .font(.system(size: 12, weight: .regular))
                                                .foregroundColor(.white)
                                        }
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(Color.gray.opacity(0.3))
                                        )
                                    }
                                    .padding(.bottom, 20)
                                }
                                .padding(.horizontal, 24)
                            }
                            .background(
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .fill(Color(red: 0x27/255, green: 0x27/255, blue: 0x27/255)) // #272727
                            )
                            .ignoresSafeArea(.all)
                        }
                        .ignoresSafeArea(.all)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
            )
            .onAppear {
                if !UserDefaults.standard.bool(forKey: "bloodPressurePopupShown") {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showPopup = true
                        }
                    }
                }
            }
        }
    }

    // MARK: - Device Tracking Question
    
    struct DeviceTrackingQuestionView: View {
        @ObservedObject var viewModel: QuestionnaireViewModel
        var completeQuestionnaire: () -> Void
        
        @State private var isWaitingForHealthKitAuth = false
        @Environment(\.adaptiveSpacing) private var spacing
        
        var body: some View {
            VStack(alignment: .center, spacing: 0) {
                Spacer()
                
                // Apple Watch image
                Image("appleWatch")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 200, height: 200)
                    .padding(.bottom, 40)
                
                // Title
                Text("Apple Health\nPermissions")
                    .font(.system(size: 31, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                
                // Description text
                VStack(alignment: .leading, spacing: 16) {
                    Text("This is essential for the app to work properly. On the next screen, we will ask permission to read your health data, such as steps, heart rate, and more to calculate your daily health scores.")
                        .font(.system(size: 12, weight: .light))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.leading)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Text("Any wearable device with Apple Health works, if you don't have one you can use your phone.")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.leading)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)

                    Spacer()
                    .frame(height: 6)

                         // Yes option
                    Button(action: {
                        viewModel.selectedDeviceTrackingStatus = .yesBoth
                        // Trigger HealthKit authorization directly and instantly
                        requestHealthKitAuthorization()
                    }) {
                        Text("Yes, I track with a device")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 25)
                                    .stroke(
                                        LinearGradient(
                                            colors: [Color("ampedGreen"), Color("ampedYellow")],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        ),
                                        lineWidth: 2
                                    )
                                    .background(
                                        RoundedRectangle(cornerRadius: 25)
                                            .fill(Color.black)
                                    )
                            )
                    }
                    .hapticFeedback(.light)
                    
                    // No option
                    Button(action: {
                        viewModel.selectedDeviceTrackingStatus = .no
                        // This is the final question, so complete the questionnaire
                        completeQuestionnaire()
                    }) {
                        Text("No, I don't use any device")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 25)
                                    .stroke(
                                        LinearGradient(
                                            colors: [Color("ampedGreen"), Color("ampedYellow")],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        ),
                                        lineWidth: 2
                                    )
                                    .background(
                                        RoundedRectangle(cornerRadius: 25)
                                            .fill(Color.black)
                                    )
                            )
                    }
                    .hapticFeedback(.light)
                }
                .padding(.horizontal, 20)
                
                Spacer()
            }
            .frame(maxHeight: .infinity)
            .ignoresSafeArea(.container, edges: .bottom)
            .onChange(of: viewModel.selectedDeviceTrackingStatus) { newValue in
                print("🔍 DEVICE TRACKING: Device tracking status changed to: \(String(describing: newValue))")
            }
        }
        
        private func requestHealthKitAuthorization() {
            print("🔍 DEVICE TRACKING: Requesting HealthKit authorization")
            print("🔍 DEVICE TRACKING: Current question before auth: \(viewModel.currentQuestion)")
            
            // Set flag to track that we're waiting for authorization
            isWaitingForHealthKitAuth = true
            
            // ULTRA-FAST: Fire the authorization immediately with completion handler
            HealthKitManager.shared.requestAuthorizationUltraFast {
                print("🔍 DEVICE TRACKING: HealthKit authorization completed")
                
                // Complete the questionnaire when authorization completes
                DispatchQueue.main.async {
                    if self.isWaitingForHealthKitAuth {
                        print("🔍 DEVICE TRACKING: Completing questionnaire")
                        self.isWaitingForHealthKitAuth = false
                        self.completeQuestionnaire()
                    }
                }
            }
            
            // DO NOT navigate yet - stay on current screen while dialog is shown
            // Navigation will happen when authorization completes
        }
    }
    
    // MARK: - Framing Comfort (tactful; no UI preference phrasing)
    struct FramingComfortQuestionView: View {
        @ObservedObject var viewModel: QuestionnaireViewModel
        @Environment(\.adaptiveSpacing) private var spacing

        var body: some View {
            VStack(alignment: .center, spacing: 0) {
                VStack(spacing: 0) {
                    Text("What helps you stay consistent?")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.bottom, 10)
                        .frame(maxWidth: .infinity)

                    ScientificCitation(text: "Helps us tailor motivation style — calculations are unchanged", metricType: nil)
                }

                AdaptiveSpacer()

                VStack(spacing: spacing.buttonSpacing) {
                    ForEach(QuestionnaireViewModel.FramingComfort.allCases, id: \.self) { option in
                        Button(action: {
                            viewModel.selectedFramingComfort = option
                            viewModel.proceedToNextQuestion()
                        }) {
                            FormattedButtonText(text: option.displayName)
                        }
                        .questionnaireButtonStyle(isSelected: viewModel.selectedFramingComfort == option)
                        .hapticFeedback(.light)
                    }
                }
                .adaptiveBottomPadding()
            }
            .padding(.horizontal, 24)
            .frame(maxHeight: .infinity)
            .adaptiveSpacing()
        }
    }

    // MARK: - Urgency Response (tactful; no countdown phrasing)
    struct UrgencyResponseQuestionView: View {
        @ObservedObject var viewModel: QuestionnaireViewModel
        @Environment(\.adaptiveSpacing) private var spacing

        var body: some View {
            VStack(alignment: .center, spacing: 0) {
                VStack(spacing: 0) {
                    Text("When timelines tighten…")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.bottom, 10)
                        .frame(maxWidth: .infinity)

                    ScientificCitation(text: "Helps us choose a motivating tone", metricType: nil)
                }

                AdaptiveSpacer()

                VStack(spacing: spacing.buttonSpacing) {
                    ForEach(QuestionnaireViewModel.UrgencyResponse.allCases, id: \.self) { option in
                        Button(action: {
                            viewModel.selectedUrgencyResponse = option
                            viewModel.proceedToNextQuestion()
                        }) {
                            FormattedButtonText(text: option.displayName)
                        }
                        .questionnaireButtonStyle(isSelected: viewModel.selectedUrgencyResponse == option)
                        .hapticFeedback(.light)
                    }
                }
                .adaptiveBottomPadding()
            }
            .padding(.horizontal, 24)
            .frame(maxHeight: .infinity)
            .adaptiveSpacing()
        }
    }

    // MARK: - Life Motivation Question
    
    struct LifeMotivationQuestionView: View {
        @ObservedObject var viewModel: QuestionnaireViewModel
        var completeQuestionnaire: () -> Void
        @Environment(\.adaptiveSpacing) private var spacing
        @State private var showPopup = false
        @State private var showDrawer = false
        
        var body: some View {
            VStack(alignment: .center, spacing: 0) {
                Spacer()
                
                // Emma character and question layout
                HStack(alignment: .top, spacing: 16) {
                    VStack(alignment: .leading, spacing: 12){
                        HStack(alignment: .center, spacing: 0){
                            // Emma character
                            Image("steptwo")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 68, height: 76)
                            
                            // Question text
                            VStack(alignment: .leading, spacing: 8) {
                                Text("What is the main reason you might want to live longer?")
                                    .font(.system(size: 20, weight: .medium))
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.leading)
                                    .lineLimit(nil)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .frame(maxWidth: .infinity, alignment: .leading)

                            }
                        }
                        // Research citation with book icon
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showDrawer = true
                            }
                        }) {
                            HStack(spacing: 6) {
                                Image("book_ribbon")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 16, height: 16)
                                
                                Text("Tap to see what research based on 195 studies tell us.")
                                    .font(.system(size: 12, weight: .regular))
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    Spacer()
                }
                .padding(.horizontal, 24)
                
                Spacer()
                 .frame(maxHeight: 32)
                
                // Life motivation options
                VStack(spacing: 16) {
                    ForEach(QuestionnaireViewModel.LifeMotivation.allCases, id: \.self) { motivation in
                        Button(action: {
                            viewModel.selectedLifeMotivation = motivation
                            
                            // Proceed to next question (sleepQuality)
                            viewModel.proceedToNextQuestion()
                        }) {
                            VStack(alignment: .center, spacing: 4) {
                                Text(motivation.mainText)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity, alignment: .center)

                                if !motivation.subText.isEmpty {
                                    Text(motivation.subText)
                                        .font(.system(size: 14, weight: .regular))
                                        .foregroundColor(.gray)
                                        .frame(maxWidth: .infinity, alignment: .center)
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, motivation.subText.isEmpty ? 18 : 8)
                            .background(
                                RoundedRectangle(cornerRadius: 100)
                                    .fill(Color.black)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 100)
                                            .stroke(
                                                LinearGradient(
                                                    colors: [Color("ampedGreen"), Color("ampedYellow")],
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                ),
                                                lineWidth: 1
                                            )
                                    )
                            )
                        }
                        .hapticFeedback(.light)
                    }
                }
                .padding(.horizontal, 24)

                Spacer()
            }
            .frame(maxHeight: .infinity)
            .ignoresSafeArea(.container, edges: .bottom)
            .overlay(
                // Popup overlay
                Group {
                    if showPopup {
                        Color.black.opacity(0.5)
                            .ignoresSafeArea()
                            .onTapGesture {
                                UserDefaults.standard.set(true, forKey: "lifeMotivationPopupShown")
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    showPopup = false
                                }
                            }

                        VStack(spacing: 0) {
                            Triangle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(
                                        stops: [
                                            .init(color: Color(red: 0.00, green: 0.57, blue: 0.27), location: 0.0),
                                            .init(color: Color(red: 0.49, green: 0.75, blue: 0.20), location: 0.9),
                                            .init(color: Color(red: 0.99, green: 0.93, blue: 0.13), location: 1.0),
                                        ]
                                        ),
                                        startPoint: .bottomLeading,
                                        endPoint: .topTrailing
                                    )
                                )
                                .frame(width: 20, height: 12)
                                .offset(y: 5)

                            VStack(spacing: 16) {
                                Text("Tap to see how this habit impacts lifespan")
                                    .font(.system(size: 20, weight: .regular))
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.leading)
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                Button(action: {
                                    UserDefaults.standard.set(true, forKey: "lifeMotivationPopupShown")
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        showPopup = false
                                    }
                                }) {
                                    Text("Okay")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(Color("ampedGreen"))
                                        .padding(.horizontal, 24)
                                        .padding(.vertical, 12)
                                        .background(
                                            RoundedRectangle(cornerRadius: 20)
                                                .fill(Color.white)
                                        )
                                }
                            }
                            .padding(.horizontal, 24)
                            .padding(.vertical, 32)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(
                                         LinearGradient(
                                        gradient: Gradient(
                                        stops: [
                                           .init(color: Color(red: 0/255, green: 146/255, blue: 69/255), location: 0.0707),
                                            .init(color: Color(red: 63/255, green: 169/255, blue: 60/255), location: 0.291),
                                            .init(color: Color(red: 126/255, green: 192/255, blue: 51/255), location: 0.5908),
                                            .init(color: Color(red: 252/255, green: 238/255, blue: 33/255), location: 0.8026)
                                        ]
                                        ),
                                        startPoint: .bottomLeading,
                                        endPoint: .topTrailing
                                    )
                            )
                            )
                        }
                        .padding(.horizontal, 40)
                        .transition(.scale.combined(with: .opacity))
                    }
                }
            )
            .overlay(
                // Drawer overlay
                Group {
                    if showDrawer {
                        ZStack(alignment: .bottom) {
                            Color.clear
                                .ignoresSafeArea(.all)
                                .onTapGesture {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        showDrawer = false
                                    }
                                }

                            VStack(spacing: 0) {
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color.white)
                                    .frame(width: 40, height: 4)
                                    .padding(.top, 8)
                                    .padding(.bottom, 20)
                                    .onTapGesture {
                                        withAnimation(.easeInOut(duration: 0.3)) {
                                            showDrawer = false
                                        }
                                    }

                                VStack(alignment: .leading, spacing: 20) {
                                    HStack {
                                        Text("Impact score")
                                            .font(.system(size: 18, weight: .regular))
                                            .foregroundColor(.white)
                                        Spacer()
                                        Button(action: {
                                            withAnimation(.easeInOut(duration: 0.3)) {
                                                showDrawer = false
                                            }
                                        }) {
                                            Image(systemName: "xmark")
                                                .font(.system(size: 16, weight: .medium))
                                                .foregroundColor(.white)
                                        }
                                    }

                                    HStack(alignment: .bottom, spacing: 0) {
                                        Text("50")
                                            .font(.system(size: 48, weight: .bold))
                                            .foregroundColor(.white)
                                        Text("/100")
                                            .font(.system(size: 24, weight: .regular))
                                            .foregroundColor(.white)
                                            .padding(.bottom, 8)
                                    }

                                    VStack(alignment: .leading, spacing: 8) {
                                        GeometryReader { geometry in
                                            ZStack(alignment: .leading) {
                                                RoundedRectangle(cornerRadius: 4)
                                                    .fill(Color.white)
                                                    .frame(height: 8)
                                                RoundedRectangle(cornerRadius: 4)
                                                    .fill(Color("ampedYellow"))
                                                    .frame(width: geometry.size.width * 0.5, height: 8)
                                                Circle()
                                                    .fill(Color.gray)
                                                    .frame(width: 20, height: 20)
                                                    .offset(x: geometry.size.width * 0.5 - 10)
                                            }
                                        }
                                        .frame(height: 20)

                                        HStack {
                                            Text("0")
                                                .font(.system(size: 12, weight: .regular))
                                                .foregroundColor(.gray)
                                            Spacer()
                                            Text("100")
                                                .font(.system(size: 12, weight: .regular))
                                                .foregroundColor(.gray)
                                        }
                                    }

                                    VStack(alignment: .leading, spacing: 12) {
                                        Text("This score estimates how your life motivation affects your life expectancy.")
                                            .font(.system(size: 16, weight: .regular))
                                            .foregroundColor(.white)
                                            .multilineTextAlignment(.leading)
                                        Text("Life motivation contributes to 10% of your total lifespan impact. It's meaningful!")
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundColor(.white)
                                            .multilineTextAlignment(.leading)
                                        Text("Having a strong life purpose can increase life expectancy by 1-2 years compared to those without clear goals.")
                                            .font(.system(size: 14, weight: .regular))
                                            .foregroundColor(.white)
                                            .multilineTextAlignment(.leading)
                                    }

                                    Button(action: { /* Handle source link tap */ }) {
                                        HStack {
                                            Text("Source: JAMA 2023")
                                                .font(.system(size: 12, weight: .regular))
                                                .foregroundColor(.white)
                                            Image(systemName: "arrow.up.right")
                                                .font(.system(size: 12, weight: .regular))
                                                .foregroundColor(.white)
                                        }
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(Color.gray.opacity(0.3))
                                        )
                                    }
                                    .padding(.bottom, 20)
                                }
                                .padding(.horizontal, 24)
                            }
                            .background(
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .fill(Color(red: 0x27/255, green: 0x27/255, blue: 0x27/255)) // #272727
                            )
                            .ignoresSafeArea(.all)
                        }
                        .ignoresSafeArea(.all)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
            )
            .onAppear {
                if !UserDefaults.standard.bool(forKey: "lifeMotivationPopupShown") {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showPopup = true
                        }
                    }
                }
            }
        }
    }
}
