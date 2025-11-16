import SwiftUI

struct NotificationCenterView: View {
    struct Notification: Identifiable {
        let id = UUID()
        let emoji: String
        let title: String
        let subtitle: String
    }
    
    let notifications: [Notification] = [
        .init(emoji: "🧘‍♂️", title: "Don’t skip today’s!", subtitle: "Your morning sessions have been amazing ☀️"),
        .init(emoji: "🙌", title: "You did it!", subtitle: "You’ve just hit a new milestone — keep the wins coming! 🎉"),
        .init(emoji: "💪", title: "Back at it?", subtitle: "You usually check in around now — let’s keep that energy up!"),
        .init(emoji: "🥳", title: "Another goal crushed!", subtitle: "Celebrate your hard work — you’ve earned it 🎉"),
        .init(emoji: "⚡️", title: "Good Morning, Adam!", subtitle: "Your battery’s full — let’s make it count ⚡️")
    ]
    
    var body: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                gradient: Gradient(colors: [Color(red: 41/255, green: 60/255, blue: 90/255), Color.black]),
                startPoint: .top,
                endPoint: .bottom
            ).ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 0) {
                Text("Notification")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.top, 18)
                    .padding(.leading, 24)
                    .padding(.bottom, 10)
                
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(notifications) { notification in
                            HStack(alignment: .top, spacing: 16) {
                                Text(notification.emoji)
                                    .font(.system(size: 32))
                                    .padding(.top, 2)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(notification.title)
                                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                                        .foregroundColor(.white)
                                    Text(notification.subtitle)
                                        .font(.system(size: 13, weight: .regular, design: .rounded))
                                        .foregroundColor(.white.opacity(0.75))
                                        .lineLimit(2)
                                }
                                Spacer()
                            }
                            .padding(14)
                            .background(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .fill(Color.white.opacity(0.07))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 18).stroke(Color.white.opacity(0.10), lineWidth: 1)
                                    )
                            )
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 6)
                }

                Spacer()
            }
        }
    }
}

#Preview {
    NotificationCenterView()
}
