import SwiftUI

/// Profile image view that matches Apple's standard design with optional edit indicator
struct ProfileImageView: View {
    @ObservedObject private var profileManager = ProfileImageManager.shared
    @State private var navigateToNotifications = false
    @State private var navigateToSettings = false
    
    // Token to trigger view refresh when profile data changes (e.g., name, gender, DOB)
    @State private var profileRefreshCounter: Int = 0
    // Token to force-refresh the avatar image when the image updates
    @State private var imageRefreshToken = UUID()
    
    let size: CGFloat
    let showBorder: Bool
    let showEditIndicator: Bool
    let showWelcomeMessage: Bool
    
    init(
        size: CGFloat,
        showBorder: Bool = false,
        showEditIndicator: Bool = false,
        showWelcomeMessage: Bool = false
    ) {
        self.size = size
        self.showBorder = showBorder
        self.showEditIndicator = showEditIndicator
        self.showWelcomeMessage = showWelcomeMessage
    }
    
    var body: some View {
        // Full header design with avatar + welcome message
        HStack(spacing: 10) {
            HStack {
                avatarView
                    .id(imageRefreshToken) // Force redraw when token changes
                
                VStack(alignment: .leading, spacing: 2) {
                    if showWelcomeMessage {
                        // Welcome message
                        Text("Welcome!")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    Text(getUserName())
                        .id(profileRefreshCounter) // re-evaluate when counter changes
                        .font(.system(size: showWelcomeMessage ? 16 : 22, weight: showWelcomeMessage ? .regular : .semibold))
                        .foregroundColor(.white)
                }
            }
            .onTapGesture {
                navigateToSettings = true
            }
            
            Spacer()
            
            // Trailing bell button styled like the screenshot (always visible)
            Button {
                navigateToNotifications = true
            } label: {
                ZStack {
                    // Subtle translucent circle
                    Circle()
                        .fill(Color.white.opacity(0.08))
                    
                    // Soft outer ring
                    Circle()
                        .stroke(Color.white.opacity(0.25), lineWidth: 1)
                    
                    // Outline bell icon
                    Image(systemName: "bell")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white.opacity(0.9))
                }
                .frame(width: 34, height: 34)
            }
            .buttonStyle(.plain)
            .contentShape(Circle())
        }
        .padding(.horizontal, 20)
        .padding(.top, 4)
        .padding(.bottom, 8)
        // Listen for profile data changes (e.g., name/gender/DOB saved)
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ProfileDataUpdated"))) { _ in
            // Bump counter to force body to re-render and re-read UserDefaults
            profileRefreshCounter &+= 1
        }
        // Also listen for profile image changes (posted by ProfileImageManager)
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ProfileImageUpdated"))) { _ in
            // Ensure we reload the image and force a redraw
            ProfileImageManager.shared.loadProfileImage()
            imageRefreshToken = UUID()
        }
        // Navigate to notification center
        .navigationDestination(isPresented: $navigateToNotifications) {
            NotificationsView()
                .navigationBarBackButtonHidden(true)
        }
        // Navigate to app settings when tapping avatar or name
        .navigationDestination(isPresented: $navigateToSettings) {
            SettingView()
                .navigationBarHidden(true)
        }
    }
    
    @ViewBuilder
    private var avatarView: some View {
        ZStack {
            // Main profile image circle with new design
            if let profileImage = profileManager.profileImage {
                Image(uiImage: profileImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: size, height: size)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(
                                showBorder ? Color(.systemGray4) : Color.clear,
                                lineWidth: showBorder ? 1 : 0
                            )
                    )
            } else {
                // New design: Circular avatar with white background and initials
                Circle()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: size, height: size)
                    .overlay(
                        Text(getInitials())
                            .id(profileRefreshCounter) // refresh initials when profile changes
                            .font(.system(size: size * 0.4, weight: .semibold))
                            .foregroundColor(.white.opacity(0.8))
                    )
                    .overlay(
                        Circle()
                            .stroke(
                                showBorder ? Color(.systemGray4) : Color.clear,
                                lineWidth: showBorder ? 1 : 0
                            )
                    )
            }
            
            // Edit indicator (pencil icon) - positioned like Apple's design
            if showEditIndicator {
                Circle()
                    .fill(Color(.systemGray5))
                    .frame(width: size * 0.3, height: size * 0.3)
                    .overlay(
                        Circle()
                            .stroke(Color(.systemBackground), lineWidth: 2)
                    )
                    .overlay(
                        Image(systemName: "pencil")
                            .font(.system(size: size * 0.12, weight: .medium))
                            .foregroundColor(.secondary)
                    )
                    .offset(x: size * 0.32, y: size * 0.32)
            }
        }
    }
    
    private func getInitials() -> String {
        let userName = UserDefaults.standard.string(forKey: UserDefaultsKeys.userName) ?? "Matt Snow"
        let components = userName.components(separatedBy: " ")
        let firstInitial = components.first?.prefix(1).uppercased() ?? "M"
        let lastInitial = components.dropFirst().first?.prefix(1).uppercased() ?? "S"
        return "\(firstInitial)\(lastInitial)"
    }
    
    private func getUserName() -> String {
        return UserDefaults.standard.string(forKey: UserDefaultsKeys.userName) ?? "Matt Snow"
    }
}

#Preview {
    VStack(spacing: 30) {
        // Small profile image without edit indicator
        ProfileImageView(size: 50, showBorder: true, showEditIndicator: false)
        
        // Medium profile image with edit indicator
        ProfileImageView(size: 80, showBorder: true, showEditIndicator: true)
        
        // Large profile image with edit indicator (settings style)
        ProfileImageView(size: 120, showBorder: true, showEditIndicator: true)
    }
    .padding()
}
