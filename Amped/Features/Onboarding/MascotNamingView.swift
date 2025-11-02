import SwiftUI

struct MascotNamingView: View {
    // MARK: - Properties
    @State private var userName: String = ""
    @State private var progress: CGFloat = 1
    
    var onContinue: ((String) -> Void)?
    
    // MARK: - Body
    var body: some View {
        ZStack {
            // Gradient Overlay
            LinearGradient.grayGradient
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                               
                // MARK: - Cute Character
                Image("battery") // Replace with your image asset name
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .shadow(color: Color.green.opacity(0.5), radius: 15, x: 0, y: 5)
                    .padding(.top, 100)
                
                // MARK: - Title
                Text("Let’s get familiar!")
                    .font(.poppins(26, weight: .bold))
                    .foregroundColor(.white)
                
                // MARK: - Progress Bar
                VStack(spacing: 4) {
                    ProgressView(value: progress, total: 13)
                        .progressViewStyle(ThickProgressViewStyle(height: 12))
                        .frame(width: 220)
                    
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
                
                // MARK: - Continue Button
                Button(action: {
                    withAnimation {
                        onContinue?(userName)
                    }
                }) {
                    Text("Continue")
                        .font(.system(size: 17, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(
                            Group {
                                if userName.isEmpty {
                                    // Disabled state
                                    Color.gray.opacity(0.4)
                                } else {
                                    // Enabled gradient
                                    LinearGradient(
                                        colors: [
                                            Color(hex: "#18EF47"),
                                            Color(hex: "#0E8929")
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                }
                            }
                        )
                        .cornerRadius(30)
                        .foregroundColor(.white)
                        .padding(.horizontal, 40)
                        .shadow(
                            color: userName.isEmpty ? .clear : Color.black.opacity(0.25),
                            radius: 5, x: 0, y: 3
                        )
                }
                .disabled(userName.isEmpty)
                .padding(.top, 10)

                
                Spacer()
            }
        }
        .navigationBarHidden(true)
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

