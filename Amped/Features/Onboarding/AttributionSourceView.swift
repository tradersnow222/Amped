import SwiftUI

/// Post-paywall attribution question.
/// Privacy-safe; stores selection locally to inform marketing and onboarding tuning.
struct AttributionSourceView: View {
    @State private var selection: AttributionSource? = nil
    @State private var otherText: String = ""
    @State private var showingOtherField = false
    var onContinue: () -> Void

    var body: some View {
        ZStack(alignment: .top) {
            Color.clear.withDeepBackground()
            VStack(spacing: 20) {
                Spacer().frame(height: 60)

                Text("Lastly, how did you hear about us?")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                Spacer()

                VStack(spacing: 12) {
                    ForEach(AttributionSource.allCases, id: \.self) { src in
                        Button(action: { 
                            selection = src
                            showingOtherField = (src == .other)
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: selection == src ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(.ampedGreen)
                                Text(src.title)
                                    .foregroundColor(.white)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)
                                Spacer()
                            }
                            .padding(.horizontal, 16)
                            .frame(height: 52)
                            .background(Color.white.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .hapticFeedback(.light)
                    }
                    
                    // Manual entry field for "Other" option
                    if showingOtherField {
                        VStack(spacing: 8) {
                            TextField("Please specify...", text: $otherText)
                                .padding(.horizontal, 16)
                                .frame(height: 44)
                                .background(Color.white.opacity(0.12))
                                .foregroundColor(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .font(.system(size: 16))
                        }
                        .padding(.top, 4)
                    }
                }
                .padding(.horizontal, 24)

                Button(action: saveAndContinue) {
                    Text("Continue")
                        .fontWeight(.bold)
                        .font(.system(.title3, design: .rounded))
                        .frame(maxWidth: .infinity, minHeight: 52)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 16)
                        .background(Color.ampedGreen)
                        .foregroundColor(.white)
                        .cornerRadius(14)
                }
                .minTappableArea(52)
                .hapticFeedback(.medium)
                .padding(.horizontal, 40)
                .shadow(color: Color.black.opacity(0.3), radius: 3, x: 0, y: 2)
                .padding(.bottom, 40)
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
    case friendsFamily, instagram, xTwitter, appStore, other

    var title: String {
        switch self {
        case .friendsFamily: return "Friends/Family"
        case .instagram: return "Instagram"
        case .xTwitter: return "X/Twitter"
        case .appStore: return "Apple Store"
        case .other: return "Other"
        }
    }
}

#Preview {
    AttributionSourceView(onContinue: {})
        .preferredColorScheme(.dark)
}
