import SwiftUI

/// Pain points selection screen: "What can we help you with?"
/// Matches questionnaire styling and focuses copy on longevity through better habits.
/// Stores selections in UserDefaults for now (no network). Applied rule: Simplicity is KING.
struct PainPointsSelectionView: View {
    @State private var selections: Set<PainPoint> = []
    var onContinue: () -> Void

    var body: some View {
        ZStack(alignment: .top) {
            Color.clear.withDeepBackground()
            VStack(spacing: 0) {
                Spacer().frame(height: 48)

                VStack(spacing: 10) {
                    Text("What can we help you with?")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("Choose the habits you want to improve to add healthy years to your life.")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.75))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }
                .padding(.horizontal, 24)

                Spacer()

                VStack(spacing: 12) {
                    ForEach(PainPoint.allCases, id: \.self) { item in
                        Button(action: { toggle(item) }) {
                            HStack(spacing: 12) {
                                Text(item.title)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                Image(systemName: selections.contains(item) ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(.ampedGreen)
                            }
                        }
                        .questionnaireButtonStyle(isSelected: selections.contains(item))
                        .hapticFeedback(.light)
                    }
                }
                .padding(.horizontal, 24)

                Spacer()

                Button(action: saveAndContinue) {
                    Text("Continue")
                }
                .continueButtonStyle()
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
            }
        }
        .navigationBarHidden(true)
    }

    private func toggle(_ item: PainPoint) {
        if selections.contains(item) { selections.remove(item) } else { selections.insert(item) }
    }

    private func saveAndContinue() {
        let ids = selections.map { $0.rawValue }
        UserDefaults.standard.set(ids, forKey: "onboarding_painpoints")
        onContinue()
    }
}

enum PainPoint: String, CaseIterable, Hashable {
    case improveSleep
    case increaseActivity
    case improveNutrition
    case lowerRestingHR
    case reduceStress

    var title: String {
        switch self {
        case .improveSleep: return "Sleep better"
        case .increaseActivity: return "Increase daily activity"
        case .improveNutrition: return "Improve nutrition quality"
        case .lowerRestingHR: return "Lower resting heart rate"
        case .reduceStress: return "Reduce stress"
        }
    }
}

#Preview {
    PainPointsSelectionView(onContinue: {})
        .preferredColorScheme(.dark)
}
