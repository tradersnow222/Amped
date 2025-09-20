import SwiftUI

/// Profile image view that matches Apple's standard design with optional edit indicator
struct ProfileImageView: View {
    // DEBUGGER MODE: Observe shared manager so UI refreshes immediately after first upload.
    // Applies rules: Simplicity is KING, MVVM + SwiftUI state management (@ObservedObject)
    @ObservedObject private var profileManager = ProfileImageManager.shared
    let size: CGFloat
    let showBorder: Bool
    let showEditIndicator: Bool
    let showWelcomeMessage: Bool
    
    // Optional: Allow passing a user profile directly for more reliable data access
    let userProfile: UserProfile?
    
    init(size: CGFloat, showBorder: Bool = false, showEditIndicator: Bool = false, showWelcomeMessage: Bool = false, userProfile: UserProfile? = nil) {
        self.size = size
        self.showBorder = showBorder
        self.showEditIndicator = showEditIndicator
        self.showWelcomeMessage = showWelcomeMessage
        self.userProfile = userProfile
    }
    
    
    var body: some View {
        if showWelcomeMessage {
            // Full header design with avatar + welcome message
            HStack {
                avatarView
                
                // Welcome message
                VStack(alignment: .leading, spacing: 2) {
                    Text("Welcome!")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text(getUserName())
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 4)
            .padding(.bottom, 8)
        } else {
            // Just the avatar
            avatarView
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
                            .font(.system(size: size * 0.4, weight: .semibold))
                            .foregroundColor(.white)
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
        let userName = getUserName()
        let components = userName.components(separatedBy: " ")
        let firstInitial = components.first?.prefix(1).uppercased() ?? "U"
        let lastInitial = components.dropFirst().first?.prefix(1).uppercased() ?? ""
        return "\(firstInitial)\(lastInitial)"
    }
    
    private func getUserName() -> String {
        // Priority 1: Use passed userProfile if available
        if let userProfile = userProfile, let firstName = userProfile.firstName, !firstName.isEmpty {
            return firstName
        }
        
        // Priority 2: Try to get from UserDefaults (from questionnaire)
        if let userName = UserDefaults.standard.string(forKey: "userName"), !userName.isEmpty {
            return userName
        }
        
        // Priority 3: Fallback to firstName from UserDefaults
        if let firstName = UserDefaults.standard.string(forKey: "userFirstName"), !firstName.isEmpty {
            return firstName
        }
        
        // Default fallback
        return "User"
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
