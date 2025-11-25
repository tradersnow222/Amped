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
    
    // MARK: - Body
    var body: some View {
        ZStack {
            // Gradient Overlay
            LinearGradient.customBlueToDarkGray
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                if isFromSettings {
                    HStack {
                        Spacer()
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark")
                                .foregroundColor(.white)
                        }
                        .padding()
                    }
                }
                
                // MARK: - Cute Character
                Image("Amped_8")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .shadow(color: Color.green.opacity(0.5), radius: 15, x: 0, y: 5)
                    .padding(.top, 70)
                
                // MARK: - Title
                Text("Let’s get familiar!")
                    .font(.poppins(26, weight: .bold))
                    .foregroundColor(.white)
                
                // MARK: - Progress Bar
                VStack(spacing: 4) {
                    ProgressView(value: progress, total: 13)
                        .progressViewStyle(ThickProgressViewStyle(height: 12))
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 40)
                    
                    Text("\(Int(progress))%")
                        .font(.poppins(12))
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(.bottom, 30)
                
                // MARK: - Question
                Text("What should we call you?")
                    .font(.poppins(18, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.bottom, 10)
                
                // MARK: - TextField
                ZStack {
                    if userName.isEmpty {
                        Text("Enter your name")
                            .foregroundColor(Color.white.opacity(0.2)) // 👈 placeholder color
                    }
                    TextField("", text: $userName)
                        .padding()
                        .frame(height: 52)
                        .frame(maxWidth: .infinity)
                        .font(.poppins(14))
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color(hex: "#0E8929"), lineWidth: 1)
                        )
                        .padding(.horizontal, 40)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .textInputAutocapitalization(.words)
                        .disableAutocorrection(true)
                }
                
                OnboardingContinueButton(
                    title: "Continue",
                    isEnabled: !userName.isEmpty,
                    animateIn: true,
                    bottomPadding: 10
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
