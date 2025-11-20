//
//  NotificationSettingsView.swift
//  Amped
//
//  Created by Sheraz Hussain on 18/11/2025.
//

import SwiftUI
import UserNotifications
import UIKit

struct NotificationsView: View {
    @Environment(\.dismiss) private var dismiss
    
    // Display model for real notifications
    private struct NotificationDisplayItem: Identifiable {
        let id: String
        let title: String
        let subtitle: String
        let date: Date?
        let categoryIdentifier: String
        let isPending: Bool
    }
    
    @State private var items: [NotificationDisplayItem] = []
    @State private var isLoading: Bool = false
    @State private var permissionAuthorized: Bool = NotificationManager.shared.isEnabled
    
    private var rowBackground: LinearGradient {
        LinearGradient(
            colors: [
                Color.white.opacity(0.10),
                Color.white.opacity(0.06)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    private var rowStroke: Color { Color.white.opacity(0.18) }
    
    var body: some View {
        ZStack {
            LinearGradient.customBlueToDarkGray
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                header
                
                if !permissionAuthorized {
                    permissionPrompt
                } else {
                    contentList
                }
            }
        }
        .navigationBarHidden(true)
        .task {
            await refreshPermission()
            await loadNotifications()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            Task {
                await refreshPermission()
                await loadNotifications()
            }
        }
    }
    
    // MARK: - Header
    
    private var header: some View {
        VStack {
            HStack {
                Button {
                    dismiss()
                } label: {
                    Image("backIcon")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                }
                .padding(.leading)
                Spacer()
                if permissionAuthorized {
                    Button {
                        NotificationManager.shared.cancelAllNotifications()
                        Task { await loadNotifications() }
                    } label: {
                        Text("Clear All")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white.opacity(0.9))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.white.opacity(0.10), in: Capsule())
                            .overlay(Capsule().stroke(Color.white.opacity(0.18), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                    .padding(.trailing, 8)
                }
            }
            
            HStack(spacing: 10) {
                Text("Notification")
                    .foregroundStyle(.white)
                    .font(.system(size: 28, weight: .bold))
                    .padding(.leading)
                
                Spacer()
            }
            .padding(.horizontal, 16)
            
        }
        .padding(.top, 8)
        .padding(.bottom, 12)
    }
    
    // MARK: - Content
    
    private var contentList: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 14) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .padding(.top, 24)
                }
                
                if items.isEmpty && !isLoading {
                    emptyState
                } else {
                    ForEach(items) { item in
                        NotificationCard(
                            emoji: emojiForCategory(item.categoryIdentifier),
                            title: item.title.isEmpty ? "(No Title)" : item.title,
                            subtitle: subtitleWithDate(item.subtitle, date: item.date, isPending: item.isPending),
                            background: rowBackground,
                            stroke: rowStroke
                        )
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .refreshable {
            await loadNotifications()
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "bell")
                .font(.system(size: 36, weight: .semibold))
                .foregroundColor(.white.opacity(0.8))
            Text("No Notifications Yet")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
            Text("When your personalized reminders arrive, they’ll show up here.")
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
        }
        .padding(.top, 40)
    }
    
    private var permissionPrompt: some View {
        VStack(spacing: 16) {
            Image(systemName: "bell.slash")
                .font(.system(size: 40, weight: .semibold))
                .foregroundColor(.white.opacity(0.9))
            
            Text("Notifications Disabled")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
            
            Text("Turn on notifications to receive smart reminders and progress updates.")
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            
            Button {
                Task {
                    _ = await NotificationManager.shared.requestPermissions()
                    await refreshPermission()
                    await loadNotifications()
                }
            } label: {
                Text("Enable Notifications")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.black)
                    .frame(height: 44)
                    .frame(maxWidth: 240)
                    .background(
                        LinearGradient(
                            colors: [Color(hex: "#18EF47"), Color(hex: "#0E8929")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .padding(.top, 6)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Mapping helpers
    
    private func emojiForCategory(_ category: String) -> String {
        // Map known categories used in NotificationManager
        switch category {
        case "GOAL_ACHIEVEMENT": return "🎉"
        case "STREAK_PROTECTION": return "🔥"
        case "MILESTONE": return "🏆"
        case "SMART_ENGAGEMENT":
            return "🌅" // morning/evening smart content
        default:
            return "🔔"
        }
    }
    
    private func subtitleWithDate(_ base: String, date: Date?, isPending: Bool) -> String {
        guard let date else { return base }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        let when = formatter.localizedString(for: date, relativeTo: Date())
        return isPending ? "\(base)\nScheduled \(when)" : "\(base)\n\(when.capitalized)"
    }
    
    // MARK: - Data loading
    
    private func refreshPermission() async {
        await withCheckedContinuation { (c: CheckedContinuation<Void, Never>) in
            UNUserNotificationCenter.current().getNotificationSettings { settings in
                DispatchQueue.main.async {
                    self.permissionAuthorized = settings.authorizationStatus == .authorized
                    c.resume()
                }
            }
        }
    }
    
    private func loadNotifications() async {
        await MainActor.run { isLoading = true }
        let center = UNUserNotificationCenter.current()
        
        // Fetch delivered notifications
        let delivered: [UNNotification] = await withCheckedContinuation { (continuation: CheckedContinuation<[UNNotification], Never>) in
            center.getDeliveredNotifications { notifications in
                continuation.resume(returning: notifications)
            }
        }
        
        // Fetch pending requests
        let pending: [UNNotificationRequest] = await withCheckedContinuation { (continuation: CheckedContinuation<[UNNotificationRequest], Never>) in
            center.getPendingNotificationRequests { requests in
                continuation.resume(returning: requests)
            }
        }
        
        // Map to display items
        var display: [NotificationDisplayItem] = []
        
        for note in delivered {
            let content = note.request.content
            let deliveredDate = note.date
            display.append(NotificationDisplayItem(
                id: note.request.identifier,
                title: content.title,
                subtitle: content.body,
                date: deliveredDate,
                categoryIdentifier: content.categoryIdentifier,
                isPending: false
            ))
        }
        
        for req in pending {
            let content = req.content
            let nextDate = (req.trigger as? UNCalendarNotificationTrigger)?.nextTriggerDate() ??
                           (req.trigger as? UNTimeIntervalNotificationTrigger).flatMap { trigger in
                               Date().addingTimeInterval(trigger.timeInterval)
                           }
            display.append(NotificationDisplayItem(
                id: req.identifier,
                title: content.title,
                subtitle: content.body,
                date: nextDate,
                categoryIdentifier: content.categoryIdentifier,
                isPending: true
            ))
        }
        
        // Sort: newest first
        display.sort { (a, b) in
            switch (a.date, b.date) {
            case let (da?, db?): return da > db
            case (nil, _?): return false
            case (_?, nil): return true
            case (nil, nil): return a.title > b.title
            }
        }
        
        await MainActor.run {
            self.items = display
            self.isLoading = false
        }
    }
}

private struct NotificationCard: View {
    let emoji: String
    let title: String
    let subtitle: String
    let background: LinearGradient
    let stroke: Color
    
    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            // Emoji icon “chip”
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.white.opacity(0.10))
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.white.opacity(0.18), lineWidth: 1)
                Text(emoji)
                    .font(.system(size: 22))
            }
            .frame(width: 48, height: 48)
            
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .foregroundColor(.white)
                    .font(.system(size: 18, weight: .semibold))
                    .multilineTextAlignment(.leading)
                
                Text(subtitle)
                    .foregroundColor(.white.opacity(0.85))
                    .font(.system(size: 13))
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(background)
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(stroke, lineWidth: 1)
                )
        )
    }
}

#Preview {
    NavigationView {
        NotificationsView()
    }
}
