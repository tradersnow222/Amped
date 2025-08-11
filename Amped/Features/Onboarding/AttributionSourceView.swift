import SwiftUI

/// Post-paywall attribution question.
/// Privacy-safe; stores selection locally to inform marketing and onboarding tuning.
struct AttributionSourceView: View {
    @State private var selection: AttributionSource? = nil
    var onContinue: () -> Void

    var body: some View {
        ZStack(alignment: .top) {
            Color.clear.withDeepBackground()
            VStack(spacing: 20) {
                Spacer().frame(height: 60)

                VStack(spacing: 10) {
                    Text("Lastly, how did you hear about us?")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    Text("Optional. Helps us improve what’s working.")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(.horizontal, 24)

                VStack(spacing: 12) {
                    ForEach(AttributionSource.allCases, id: \.self) { src in
                        Button(action: { selection = src }) {
                            HStack(spacing: 12) {
                                Image(systemName: selection == src ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(.ampedGreen)
                                Text(src.title)
                                    .foregroundColor(.white)
                                Spacer()
                            }
                            .padding(.horizontal, 16)
                            .frame(height: 52)
                            .background(Color.white.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .hapticFeedback(.light)
                    }
                }
                .padding(.horizontal, 24)

                Spacer()

                Button(action: saveAndContinue) {
                    Text("Continue")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(Color.ampedGreen)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
            }
        }
        .navigationBarHidden(true)
    }

    private func saveAndContinue() {
        if let selection { UserDefaults.standard.set(selection.rawValue, forKey: "onboarding_attribution") }
        onContinue()
    }
}

enum AttributionSource: String, CaseIterable, Hashable {
    case tv, instagram, facebook, appStore, youtube, friendOrFamily, webSearch, xTwitter, other

    var title: String {
        switch self {
        case .tv: return "TV"
        case .instagram: return "Instagram"
        case .facebook: return "Facebook"
        case .appStore: return "App Store"
        case .youtube: return "YouTube"
        case .friendOrFamily: return "Friend or family"
        case .webSearch: return "Web search"
        case .xTwitter: return "X / Twitter"
        case .other: return "Other"
        }
    }
}

#Preview {
    AttributionSourceView(onContinue: {})
        .preferredColorScheme(.dark)
}
