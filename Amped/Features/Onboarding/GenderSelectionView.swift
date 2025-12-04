import SwiftUI

struct GenderSelectionView: View {
    @EnvironmentObject private var appState: AppState

    @State var progress: CGFloat = 2
    var isFromSettings: Bool = false
    var onContinue: ((Gender) -> Void)?
    var onBack: (() -> Void)?

    @State private var selected: Gender? = nil

    enum Gender: String, CaseIterable { case male = "Male", female = "Female" }
    
    // Adaptive sizing
    private var isPad: Bool { UIDevice.current.userInterfaceIdiom == .pad }
    private var mascotSize: CGFloat { isPad ? 180 : 120 }
    private var titleSize: CGFloat { isPad ? 34 : 26 }
    private var progressHeight: CGFloat { isPad ? 16 : 12 }
    private var progressTextSize: CGFloat { isPad ? 14 : 12 }
    private var questionFontSize: CGFloat { isPad ? 22 : 18 }
    private var avatarCircleSize: CGFloat { isPad ? 110 : 82 }
    private var avatarImagePadding: CGFloat { isPad ? 8 : 4 }
    private var avatarTitleSize: CGFloat { isPad ? 18 : 14 }
    private var backIconSize: CGFloat { isPad ? 24 : 20 }
    private var hStackSpacing: CGFloat { isPad ? 80 : 40 }

    var body: some View {
        ZStack {
            LinearGradient.customBlueToDarkGray
                .ignoresSafeArea()

            VStack(spacing: isPad ? 36 : 30) {
                
                HStack {
                    Button(action: {
                        onBack?()
                    }) {
                        Image("backIcon")
                            .resizable()
                            .scaledToFit()
                            .frame(width: backIconSize, height: backIconSize)
                    }
                    .padding(.leading, 30)
                    .padding(.top, isPad ? 16 : 10)
                    
                    Spacer()
                }
                
                Image("Amped_8")
                    .resizable()
                    .scaledToFit()
                    .frame(width: mascotSize, height: mascotSize)
                    .shadow(color: Color.green.opacity(0.5), radius: isPad ? 18 : 15, x: 0, y: 5)
                    .padding(.top, isPad ? 28 : 20)

                Text("Let’s get familiar!")
                    .font(.poppins(titleSize, weight: .bold))
                    .foregroundColor(.white)

                VStack(spacing: 4) {
                    ProgressView(value: progress, total: 13)
                        .progressViewStyle(ThickProgressViewStyle(height: progressHeight))
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, isPad ? 60 : 40)

                    Text("8%")
                        .font(.poppins(progressTextSize))
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(.bottom, isPad ? 36 : 30)

                Text("Are you team He or She?")
                    .font(.poppins(questionFontSize, weight: .medium))
                    .foregroundColor(.white)

                HStack(spacing: hStackSpacing) {
                    SelectableAvatar(
                        title: "Male",
                        isSelected: selected == .male,
                        imageName: "maleIcon",
                        circleSize: avatarCircleSize,
                        imagePadding: avatarImagePadding,
                        titleFontSize: avatarTitleSize
                    ) {
                        selected = .male
                        if let onContinue, let selected {
                            onContinue(selected)
                        }
                    }
                    SelectableAvatar(
                        title: "Female",
                        isSelected: selected == .female,
                        imageName: "femaleIcon",
                        circleSize: avatarCircleSize,
                        imagePadding: avatarImagePadding,
                        titleFontSize: avatarTitleSize
                    ) {
                        selected = .female
                        if let onContinue, let selected {
                            onContinue(selected)
                        }
                    }
                }
                .padding(.top, 10)

                Spacer()
            }
        }
        .navigationBarBackButtonHidden(false)
        .onAppear {
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
    let circleSize: CGFloat
    let imagePadding: CGFloat
    let titleFontSize: CGFloat
    let action: () -> Void

    private var isPad: Bool { UIDevice.current.userInterfaceIdiom == .pad }

    var body: some View {
        VStack(spacing: 8) {
            ZStack(alignment: .topTrailing) {
                Circle()
                    .fill(Color.black.opacity(0.2))
                    .overlay(
                        Circle().stroke(Color.white.opacity(0.25), lineWidth: isPad ? 4 : 3)
                    )
                    .frame(width: circleSize, height: circleSize)
                    .overlay(
                        Image(imageName)
                            .resizable()
                            .scaledToFit()
                            .padding(imagePadding)
                    )
                    .overlay(
                        Circle()
                            .stroke(isSelected ? Color(hex: "#0E8929") : Color.clear, lineWidth: isPad ? 4 : 3)
                    )

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: isPad ? 22 : 18))
                        .foregroundColor(Color(hex: "#18EF47"))
                        .background(
                            Circle().fill(Color.black.opacity(0.6)).frame(width: isPad ? 26 : 22, height: isPad ? 26 : 22)
                        )
                        .offset(x: isPad ? 6 : 4, y: isPad ? -7 : -5)
                }
            }
            Text(title)
                .font(.poppins(titleFontSize))
                .foregroundColor(.white)
        }
        .onTapGesture { action() }
    }
}
