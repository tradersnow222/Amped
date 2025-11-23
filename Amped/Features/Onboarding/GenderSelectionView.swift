import SwiftUI

struct GenderSelectionView: View {
    @EnvironmentObject private var appState: AppState

    @State var progress: CGFloat = 2
    var isFromSettings: Bool = false
    var onContinue: ((Gender) -> Void)?
    var onBack: (() -> Void)?

    @State private var selected: Gender? = nil

    enum Gender: String, CaseIterable { case male = "Male", female = "Female" }

    var body: some View {
        ZStack {
            LinearGradient.customBlueToDarkGray
                .ignoresSafeArea()

            VStack(spacing: 30) {
                
                HStack {
                    Button(action: {
                        // back action
                        onBack?()
                    }) {
                        Image("backIcon")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                    }
                    .padding(.leading, 30)
                    .padding(.top, 10)
                    
                    Spacer() // pushes button to leading
                }
                
                Image("battery")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .shadow(color: Color.green.opacity(0.5), radius: 15, x: 0, y: 5)
                    .padding(.top, 20)

                Text("Let’s get familiar!")
                    .font(.poppins(26, weight: .bold))
                    .foregroundColor(.white)

                VStack(spacing: 4) {
                    ProgressView(value: progress, total: 13)
                        .progressViewStyle(ThickProgressViewStyle(height: 12))
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 40)

                    Text("8%")
                        .font(.poppins(12))
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(.bottom, 30)

                Text("Are you team He or She?")
                    .font(.poppins(18, weight: .medium))
                    .foregroundColor(.white)

                HStack(spacing: 40) {
                    SelectableAvatar(title: "Male", isSelected: selected == .male, imageName: "maleIcon") {
                        selected = .male
                    }
                    SelectableAvatar(title: "Female", isSelected: selected == .female, imageName: "femaleIcon") {
                        selected = .female
                    }
                }
                .padding(.top, 10)

                OnboardingContinueButton(
                    title: "Continue",
                    isEnabled: selected != nil,
                    animateIn: true,
                    bottomPadding: 0
                ) {
                    if let onContinue, let selected {
                        onContinue(selected)
                    }
                }
                .padding(.top, 10)

                Spacer()
            }
        }
        .navigationBarBackButtonHidden(false)
        .onAppear {
            // If launched from Settings, prefill from defaults
            if isFromSettings {
                let saved = appState.getFromUserDefault(key: UserDefaultsKeys.userGender)
                if !saved.isEmpty {
                    selected = Gender(rawValue: saved)
                }
            }
        }
    }
}

#Preview {
    GenderSelectionView()
}

private struct SelectableAvatar: View {
    let title: String
    let isSelected: Bool
    let imageName: String
    let action: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            ZStack(alignment: .topTrailing) {
                Circle()
                    .fill(Color.black.opacity(0.2))
                    .overlay(
                        Circle().stroke(Color.white.opacity(0.25), lineWidth: 3)
                    )
                    .frame(width: 82, height: 82)
                    .overlay(
                        Image(imageName)
                            .resizable()
                            .scaledToFit()
                            .padding(4)
                    )
                    .overlay(
                        Circle()
                            .stroke(isSelected ? Color(hex: "#0E8929") : Color.clear, lineWidth: 3)
                    )

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(Color(hex: "#18EF47"))
                        .background(
                            Circle().fill(Color.black.opacity(0.6)).frame(width: 22, height: 22)
                        )
                        .offset(x: 4, y: -5)
                }
            }
            Text(title)
                .font(.poppins(14))
                .foregroundColor(.white)
        }
        .onTapGesture { action() }
    }
}
