import SwiftUI

/// Introduction to personalization and questionnaire - builds credibility with scientific backing
struct PersonalizationIntroView: View {
    // MARK: - Properties
    
    // PERFORMANCE FIX: Remove unnecessary @StateObject that blocks main thread
    @State private var animateElements = false
    @EnvironmentObject var themeManager: BatteryThemeManager
    
    // Callback to proceed to next step
    var onContinue: (() -> Void)?
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // Background image with overlay
            GeometryReader { geometry in
                Image("personalization")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geometry.size.width, height: geometry.size.height, alignment: .top)
                    .offset(y: -180)
                    .clipped()
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                
                // Linear gradient overlay matching exact specifications
                LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: Color(red: 102/255, green: 102/255, blue: 102/255).opacity(0.0), location: 0.0),     // rgba(102, 102, 102, 0) at 0%
                        .init(color: Color(red: 51/255, green: 51/255, blue: 51/255).opacity(0.5), location: 0.3894),     // rgba(51, 51, 51, 0.5) at 38.94%
                        .init(color: Color.black, location: 0.6635)                                                      // #000000 at 66.35%
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            .edgesIgnoringSafeArea(.all)
            
            // Main content - all content grouped together at bottom
            VStack {
                Spacer()
                
                VStack(spacing: 48) {
                    VStack(spacing: 0) {
                        // Main headline with gradient text
                        VStack(spacing: 0) {
                            HStack(spacing: 0) {
                                Text("Driven By ")
                                    .font(.system(size: 32, weight: .bold, design: .default))
                                    .foregroundColor(.white)
                                Text("Data")
                                    .font(.system(size: 32, weight: .bold, design: .default))
                                    .foregroundStyle(
                                        LinearGradient(
                                            gradient: Gradient(stops: [
                                                .init(color: Color(red: 252/255, green: 238/255, blue: 33/255), location: 0.0707),  // #FCEE21 at 7.07%
                                                .init(color: Color(red: 0/255, green: 146/255, blue: 69/255), location: 0.8026)     // #009245 at 80.26%
                                            ]),
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                            }
                            .multilineTextAlignment(.center)
                            .opacity(animateElements ? 1 : 0)
                            .offset(y: animateElements ? 0 : 20)
                            .animation(.easeOut(duration: 0.8).delay(0.2), value: animateElements)
                            
                            HStack(spacing: 0) {
                                Text("Fuelled By ")
                                    .font(.system(size: 32, weight: .bold, design: .default))
                                    .foregroundColor(.white)
                                Text("AI")
                                    .font(.system(size: 32, weight: .bold, design: .default))
                                    .foregroundStyle(
                                        LinearGradient(
                                            gradient: Gradient(stops: [
                                                .init(color: Color(red: 252/255, green: 238/255, blue: 33/255), location: 0.0707),  // #FCEE21 at 7.07%
                                                .init(color: Color(red: 0/255, green: 146/255, blue: 69/255), location: 0.8026)     // #009245 at 80.26%
                                            ]),
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                            }
                            .multilineTextAlignment(.center)
                            .opacity(animateElements ? 1 : 0)
                            .offset(y: animateElements ? 0 : 20)
                            .animation(.easeOut(duration: 0.8).delay(0.3), value: animateElements)
                        }
                        
                        // Statistics section
                        VStack(spacing: 8) {
                            Text("Our AI lifespan models are based on")
                                .font(.system(size: 16, weight: .regular, design: .default))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                                .opacity(animateElements ? 1 : 0)
                                .offset(y: animateElements ? 0 : 20)
                                .animation(.easeOut(duration: 0.8).delay(0.4), value: animateElements)
                            
                            highlightedText(
                                fullText: "200+ peer-reviewed studies with over 10 million participants",
                                highlightedParts: ["200+ peer-reviewed", "10 million"],
                                highlightColor: Color(red: 250/255, green: 192/255, blue: 60/255)
                            )
                            .opacity(animateElements ? 1 : 0)
                            .offset(y: animateElements ? 0 : 20)
                            .animation(.easeOut(duration: 0.8).delay(0.5), value: animateElements)
                        }
                        .padding(.top, 20)
                        
                        // Expert insights text
                        Text("with insights from experts at")
                            .font(.system(size: 16, weight: .regular, design: .default))
                            .foregroundColor(Color(red: 250/255, green: 192/255, blue: 60/255)) // #FAC03C
                            .multilineTextAlignment(.center)
                            .padding(.top, 20)
                            .opacity(animateElements ? 1 : 0)
                            .offset(y: animateElements ? 0 : 20)
                            .animation(.easeOut(duration: 0.8).delay(0.6), value: animateElements)
                        
                        // University logos
                        HStack(spacing: 24) {
                            ForEach(ResearchInstitute.allCases, id: \.self) { institute in
                                universityLogoView(for: institute)
                            }
                        }
                        .padding(.top, 20)
                        .opacity(animateElements ? 1 : 0)
                        .offset(y: animateElements ? 0 : 20)
                        .animation(.easeOut(duration: 0.8).delay(0.7), value: animateElements)
                    }
                    .padding(.horizontal, 24)
                    
                    // Continue button
                    Button(action: {
                        onContinue?()
                    }) {
                        Text("Continue")
                    }
                    .primaryButtonStyle()
                    .padding(.horizontal, 28)
                    .opacity(animateElements ? 1 : 0)
                    .scaleEffect(animateElements ? 1 : 0.9)
                    .animation(.easeOut(duration: 0.8).delay(0.8), value: animateElements)
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            withAnimation {
                animateElements = true
            }
        }
    }
    
    // MARK: - Subviews
    
    private func universityLogoView(for institute: ResearchInstitute) -> some View {
        Image(institute.rawValue.lowercased())
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(height: 24)
            .opacity(0.8)
    }
    
    private func highlightedText(fullText: String, highlightedParts: [String], highlightColor: Color) -> some View {
        let attributedString = NSMutableAttributedString(string: fullText)
        let baseAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 16, weight: .regular),
            .foregroundColor: UIColor.white
        ]
        let highlightAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 16, weight: .bold),
            .foregroundColor: UIColor(highlightColor)
        ]
        
        attributedString.addAttributes(baseAttributes, range: NSRange(location: 0, length: fullText.count))
        
        for part in highlightedParts {
            let range = (fullText as NSString).range(of: part)
            if range.location != NSNotFound {
                attributedString.addAttributes(highlightAttributes, range: range)
            }
        }
        
        return Text(AttributedString(attributedString))
            .multilineTextAlignment(.center)
            .lineLimit(nil)
            .fixedSize(horizontal: false, vertical: true)
    }
}

// MARK: - ViewModel

final class PersonalizationIntroViewModel: ObservableObject {
    @Published var showQuestionnaire = false
    
    func proceedToQuestionnaire() {
        showQuestionnaire = true
    }
}

// MARK: - Preview

struct PersonalizationIntroView_Previews: PreviewProvider {
    static var previews: some View {
        PersonalizationIntroView(onContinue: {})
            .environmentObject(BatteryThemeManager())
    }
}
