import SwiftUI

struct MascotNamingView: View {
    // MARK: - Environment
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appState: AppState
    
    // MARK: - Properties
    @State private var userName: String = ""
    @State private var progress: CGFloat = 1
    
    // When true, this screen is being used from Settings rather than onboarding.
    var isFromSettings: Bool = false
    
    // Onboarding flow continuation closure (unused when from Settings)
    var onContinue: ((String) -> Void)?
    
    // MARK: - Adaptive Sizing
    private var isPad: Bool { UIDevice.current.userInterfaceIdiom == .pad }
    private var mascotSize: CGFloat { isPad ? 180 : 120 }
    private var titleFontSize: CGFloat { isPad ? 34 : 26 }
    private var progressHeight: CGFloat { isPad ? 16 : 12 }
    private var progressTextSize: CGFloat { isPad ? 14 : 12 }
    private var questionFontSize: CGFloat { isPad ? 22 : 18 }
    private var textFieldFontSize: CGFloat { isPad ? 18 : 14 }
    private var textFieldHeight: CGFloat { isPad ? 60 : 52 }
    private var horizontalFieldPadding: CGFloat { isPad ? 80 : 40 }
    private var verticalSpacing: CGFloat { isPad ? 36 : 30 }
    private var topImagePadding: CGFloat { isPad ? 80 : 70 }
    private var buttonBottomPadding: CGFloat { isPad ? 20 : 10 }
    
    // MARK: - Body
    var body: some View {
        ZStack {
            // Gradient Overlay
            LinearGradient.customBlueToDarkGray
                .ignoresSafeArea()
            
            VStack(spacing: verticalSpacing) {
                if isFromSettings {
                    HStack {
                        Spacer()
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark")
                                .foregroundColor(.white)
                                .font(.system(size: isPad ? 20 : 17, weight: .regular))
                        }
                        .padding()
                    }
                }
                
                // MARK: - Cute Character
                Image("Amped_8")
                    .resizable()
                    .scaledToFit()
                    .frame(width: mascotSize, height: mascotSize)
                    .shadow(color: Color.green.opacity(0.5), radius: isPad ? 18 : 15, x: 0, y: 5)
                    .padding(.top, topImagePadding)
                
                // MARK: - Title
                Text("Let’s get familiar!")
                    .font(.poppins(titleFontSize, weight: .bold))
                    .foregroundColor(.white)
                
                // MARK: - Progress Bar
                VStack(spacing: 6) {
                    ProgressView(value: progress, total: 13)
                        .progressViewStyle(ThickProgressViewStyle(height: progressHeight))
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, isPad ? 80 : 40)
                    
                    Text("\(Int(progress))%")
                        .font(.poppins(progressTextSize))
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(.bottom, isPad ? 36 : 30)
                
                // MARK: - Question
                Text("What should we call you?")
                    .font(.poppins(questionFontSize, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.bottom, isPad ? 12 : 10)
                
                // MARK: - TextField
                ZStack {
                    if userName.isEmpty {
                        Text("Enter your name")
                            .foregroundColor(Color.white.opacity(0.2)) // 👈 placeholder color
                            .font(.poppins(textFieldFontSize))
                    }
                    TextField("", text: $userName)
                        .padding()
                        .frame(height: textFieldHeight)
                        .frame(maxWidth: .infinity)
                        .font(.poppins(textFieldFontSize))
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color(hex: "#0E8929"), lineWidth: 1)
                        )
                        .padding(.horizontal, horizontalFieldPadding)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .textInputAutocapitalization(.words)
                        .disableAutocorrection(true)
                }
                
                OnboardingContinueButton(
                    title: "Continue",
                    isEnabled: !userName.isEmpty,
                    animateIn: true,
                    bottomPadding: buttonBottomPadding
                ) {
                    if isFromSettings {
                        NotificationCenter.default.post(name: NSNotification.Name("ProfileDataUpdated"), object: nil)
                    }
                    onContinue?(userName)
                }
                
                Spacer()
            }
        }
        // Show nav bar when coming from Settings; onboarding keeps it hidden
        .navigationBarHidden(!isFromSettings)
        .onAppear {
            // If launched from Settings, prefill from defaults
            if isFromSettings {
                let saved = appState.getFromUserDefault(key: UserDefaultsKeys.userName)
                if !saved.isEmpty {
                    userName = saved
                }
            }
        }
    }
}

struct ThickProgressViewStyle: ProgressViewStyle {
    var height: CGFloat = 10
    var backgroundColor: Color = Color.white.opacity(0.2)
    var foregroundColor: Color = Color(hex: "#00E676")
    
    func makeBody(configuration: Configuration) -> some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(backgroundColor)
                    .frame(height: height)
                
                Capsule()
                    .fill(foregroundColor)
                    .frame(width: geo.size.width * CGFloat(configuration.fractionCompleted ?? 0),
                           height: height)
            }
        }
        .frame(height: height)
    }
}

struct MascotNamingView_Previews: PreviewProvider {
    static var previews: some View {
        MascotNamingView(isFromSettings: true)
            .environmentObject(AppState())
    }
}
