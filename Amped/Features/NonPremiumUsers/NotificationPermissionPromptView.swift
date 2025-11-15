import SwiftUI

struct NotificationPermissionPromptView: View {
    // Closure callbacks for button actions
    var onAllow: (() -> Void)? = nil
    var onNotNow: (() -> Void)? = nil

    var body: some View {
        ZStack {
            // Blurred/Dimmed background
            Color.black.opacity(0.45)
                .ignoresSafeArea()

            VStack {
                Spacer()

                VStack(spacing: 26) {
                    // Cute battery character image
                    Image("batteryCharacter") // Replace with your image asset name
                        .resizable()
                        .scaledToFit()
                        .frame(width: 104, height: 104)
                        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                        .shadow(color: Color.black.opacity(0.17), radius: 16, y: 4)

                    Text("Amped Would Like to Send You Notifications")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)

                    Text("It may include alerts, sounds, and icon badges. These can be configured in Settings.")
                        .font(.system(size: 15, weight: .regular, design: .rounded))
                        .foregroundColor(.white.opacity(0.82))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)

                    VStack(spacing: 14) {
                        Button(action: { onAllow?() }) {
                            Text("Allow")
                                .font(.system(size: 17, weight: .semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(
                                    LinearGradient(colors: [Color.green, Color.green], startPoint: .leading, endPoint: .trailing)
                                )
                                .foregroundColor(.white)
                                .cornerRadius(22)
                        }
                        .buttonStyle(PlainButtonStyle())
                        Button(action: { onNotNow?() }) {
                            Text("Not now")
                                .font(.system(size: 17, weight: .medium))
                                .foregroundColor(.white.opacity(0.84))
                                .padding(.vertical, 11)
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(28)
                .background(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(Color.white.opacity(0.08))
                        .background(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 28).stroke(Color.white.opacity(0.18), lineWidth: 1)
                        )
                )
                .padding(.horizontal, 24)
                .shadow(color: Color.black.opacity(0.22), radius: 28, y: 8)

                Spacer()
            }
        }
    }
}

#Preview {
    NotificationPermissionPromptView()
}
