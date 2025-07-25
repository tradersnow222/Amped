import SwiftUI

/// Profile image view that matches Apple's standard design with optional edit indicator
struct ProfileImageView: View {
    let size: CGFloat
    let showBorder: Bool
    let showEditIndicator: Bool
    
    init(size: CGFloat, showBorder: Bool = false, showEditIndicator: Bool = false) {
        self.size = size
        self.showBorder = showBorder
        self.showEditIndicator = showEditIndicator
    }
    
    var body: some View {
        ZStack {
            // Main profile image circle
            if let profileImage = ProfileImageManager.shared.profileImage {
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
                // Default avatar with initials - clean, no background
                Circle()
                    .stroke(
                        showBorder ? Color(.systemGray4) : Color.clear,
                        lineWidth: showBorder ? 1 : 0
                    )
                    .frame(width: size, height: size)
                    .overlay(
                        Text(getInitials())
                            .font(.system(size: size * 0.4, weight: .medium))
                            .foregroundColor(.primary)
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
        let userName = UserDefaults.standard.string(forKey: "userName") ?? "Matt Snow"
        let components = userName.components(separatedBy: " ")
        let firstInitial = components.first?.prefix(1).uppercased() ?? "M"
        let lastInitial = components.dropFirst().first?.prefix(1).uppercased() ?? "S"
        return "\(firstInitial)\(lastInitial)"
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
