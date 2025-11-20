import SwiftUI
import AVFoundation
import AVKit

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
            
            Image("femaleBg")
                .resizable()
                .scaledToFill()
                .opacity(0.40)
                .ignoresSafeArea()
            
            LinearGradient.ampBlueGradient
                .ignoresSafeArea()
            
            VStack {
                Spacer()
                
                // MARK: Text Content
                VStack(alignment: .leading, spacing: 12) {
                    Text("Sync Your World. \nSee the Truth.")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .font(.poppins(40, weight: .bold))
                        .foregroundColor(.white)
                        .shadow(radius: 3)
                        .opacity(animateElements ? 1 : 0)
                        .offset(y: animateElements ? 0 : 40)
                        .animation(.easeOut(duration: 0.8).delay(0.1), value: animateElements)
                        .padding(.leading, 30)
                    
                    
                    Text("Connect Apple Health and let Amped \nturn your steps, sleep, and workouts into \nreal time gained or lost.")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .font(.poppins(18))
                        .foregroundColor(.white.opacity(0.85))
                        .opacity(animateElements ? 1 : 0)
                        .offset(y: animateElements ? 0 : 40)
                        .animation(.easeOut(duration: 0.8).delay(0.3), value: animateElements)
                        .padding(.leading, 30)
                }
                .padding(.bottom, 30)
                
                OnboardingContinueButton(
                    title: "Continue",
                    isEnabled: true,
                    animateIn: animateElements,
                    bottomPadding: 50
                ) {
                    onContinue?()
                }
            }
        }
        .onAppear {
            // Trigger animation when the view appears
            animateElements = true
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


struct OnboardingContinueButton: View {
    var title: String = "Continue"
    var isEnabled: Bool = true
    var animateIn: Bool = true
    var bottomPadding: CGFloat = 50
    var action: () -> Void

    var body: some View {
        Button(action: {
            guard isEnabled else { return }
            withAnimation(.easeInOut(duration: 0.3)) {
                action()
            }
        }) {
            HStack {
                Text(title)
                    .font(.poppins(20, weight: .medium))
                Image(systemName: "arrow.right")
                    .font(.system(size: 17, weight: .semibold))
            }
            .foregroundColor(.black)
            .padding()
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                isEnabled
                ? LinearGradient.ampButtonGradient
                : LinearGradient.mpButtonGrayGradient
            )
            .cornerRadius(30)
            .padding(.horizontal, 30)
            .shadow(color: Color.black.opacity(isEnabled ? 0.3 : 0.0), radius: 5, x: 0, y: 3)
            .opacity(animateIn ? 1 : 0)
            .offset(y: animateIn ? 0 : 50)
            .scaleEffect(animateIn ? 1 : 0.9)
            .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.6), value: animateIn)
        }
        .disabled(!isEnabled)
        .padding(.bottom, bottomPadding)
    }
}
