import SwiftUI

/// Custom modal view for notification permission
struct NotificationPermissionView1: View {
    var onDismiss: (() -> Void)?
    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
            VStack(spacing: 24) {
                Spacer()
                VStack(spacing: 24) {
                    Image("emma")
                        .resizable()
                        .frame(width: 80, height: 80)
                    Text("Amped Would Like to Send You Notifications")
                        .font(.system(size: 20, weight: .semibold))
                        .multilineTextAlignment(.center)
                        .foregroundColor(.white)
                    Text("It may include alerts, sounds, and icon badges. These can be configured in Settings.")
                        .font(.system(size: 15, weight: .regular))
                        .multilineTextAlignment(.center)
                        .foregroundColor(.white.opacity(0.8))
                    VStack(spacing: 12) {
                        Button(action: {
                            onDismiss?()
                            // TODO: Request notification permissions here
                        }) {
                            Text("Allow")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 28)
                                        .fill(
                                            LinearGradient(
                                                gradient: Gradient(colors: [Color.green, Color.yellow]),
                                                startPoint: .leading, endPoint: .trailing)
                                        )
                                )
                        }
                        Button(action: { onDismiss?() }) {
                            Text("Not now")
                                .font(.system(size: 18, weight: .regular))
                                .foregroundColor(.white.opacity(0.7))
                                .padding()
                        }
                    }
                }
                .padding(32)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color.white.opacity(0.13))
                        .background(
                            RoundedRectangle(cornerRadius: 24).stroke(Color.white.opacity(0.19), lineWidth: 1)
                        )
                )
                .padding(.horizontal, 24)
                Spacer()
            }
        }
    }
}

#Preview {
    NotificationPermissionView1(onDismiss: nil)
}
