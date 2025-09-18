import SwiftUI

/// Post-paywall attribution question with friendly turtle character and gradient buttons.
/// Privacy-safe; stores selection locally to inform marketing and onboarding tuning.
struct AttributionSourceView: View {
    @State private var selection: AttributionSource? = nil
    @State private var otherText: String = ""
    @State private var showingOtherField = false
    var onContinue: () -> Void

    var body: some View {
        ZStack(alignment: .top) {
            Color.black
                .ignoresSafeArea()
            
            VStack(spacing: 32) {
                // Top spacing
                Spacer()
                // Character and question layout - matching name view pattern
                HStack(alignment: .center, spacing: 16) {
                    // Turtle character
                    Image("steptwo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 68, height: 76)
                    
                    // Question text - matching name view layout
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Lastly, where did you hear from us?")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.leading)
                            .lineLimit(nil)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(.horizontal, 24)
                // Attribution options with custom gradient border style
                VStack(spacing: 16) {
                    ForEach(AttributionSource.allCases, id: \.self) { src in
                        Button(action: { 
                            selection = src
                            showingOtherField = (src == .other)
                            
                            // Auto-continue for non-other options
                            if src != .other {
                                saveAndContinue()
                            }
                        }) {
                            Text(src.title)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(
                                    RoundedRectangle(cornerRadius: 100)
                                        .fill(Color.black)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 100)
                                                .stroke(
                                                    LinearGradient(
                                                        gradient: Gradient(stops: [
                                                            .init(color: Color(red: 0/255, green: 146/255, blue: 69/255), location: 0.0),     // #009245
                                                            .init(color: Color(red: 252/255, green: 238/255, blue: 33/255), location: 1.0)     // #FCEE21
                                                        ]),
                                                        startPoint: .leading,
                                                        endPoint: .trailing
                                                    ),
                                                    lineWidth: selection == src ? 2 : 1
                                                )
                                        )
                                )
                        }
                        .hapticFeedback(.light)
                    }
                    
                    // Manual entry field for "Other" option
                    if showingOtherField {
                        VStack(spacing: 8) {
                            TextField("Please specify...", text: $otherText)
                                .padding(.horizontal, 16)
                                .frame(height: 52)
                                .background(
                                    RoundedRectangle(cornerRadius: 100)
                                        .fill(Color.black)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 100)
                                                .stroke(
                                                    LinearGradient(
                                                        gradient: Gradient(stops: [
                                                            .init(color: Color(red: 0/255, green: 146/255, blue: 69/255), location: 0.0),
                                                            .init(color: Color(red: 252/255, green: 238/255, blue: 33/255), location: 1.0)
                                                        ]),
                                                        startPoint: .leading,
                                                        endPoint: .trailing
                                                    ),
                                                    lineWidth: 1
                                                )
                                        )
                                )
                                .foregroundColor(.white)
                                .font(.system(size: 16))
                                .onSubmit {
                                    // Auto-continue when user presses return/done
                                    saveAndContinue()
                                }
                        }
                        .padding(.top, 4)
                    }
                }
                .padding(.horizontal, 24)
                
                Spacer()
            }
        }
        .bottomSafeAreaPadding() // Keep bottom button clear of the home indicator (iOS 16+ compatible)
        .navigationBarHidden(true)
    }

    private func saveAndContinue() {
        if let selection { 
            UserDefaults.standard.set(selection.rawValue, forKey: "onboarding_attribution")
            
            // Save the "Other" text if applicable
            if selection == .other && !otherText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                UserDefaults.standard.set(otherText.trimmingCharacters(in: .whitespacesAndNewlines), forKey: "onboarding_attribution_other_text")
            }
        }
        onContinue()
    }
}

enum AttributionSource: String, CaseIterable, Hashable {
    case friendsFamily, appStore, twitter, instagram, other

    var title: String {
        switch self {
        case .friendsFamily: return "Friends/Family"
        case .appStore: return "Apple Store"
        case .twitter: return "X / Twitter"
        case .instagram: return "Instagram"
        case .other: return "Other"
        }
    }
}

#Preview {
    AttributionSourceView(onContinue: {})
        .preferredColorScheme(.dark)
}
