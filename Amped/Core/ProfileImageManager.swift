import Foundation
import UIKit
import SwiftUI

/// Centralized manager for handling user profile images throughout the app
/// Following Apple guidelines for consistent UI and proper storage
@MainActor
class ProfileImageManager: ObservableObject {
    static let shared = ProfileImageManager()
    
    @Published var profileImage: UIImage?
    
    private let userDefaultsKey = "userProfileImage"
    
    private init() {
        loadProfileImage()
    }
    
    /// Load the saved profile image from UserDefaults
    func loadProfileImage() {
        if let imageData = UserDefaults.standard.data(forKey: userDefaultsKey),
           let savedImage = UIImage(data: imageData) {
            profileImage = savedImage
        } else {
            profileImage = nil
        }
    }
    
    /// Save a new profile image
    func saveProfileImage(_ image: UIImage) {
        // Resize image to standard size for consistency
        let resizedImage = resizeImage(image, to: CGSize(width: 200, height: 200))
        profileImage = resizedImage
        
        // Save to UserDefaults
        if let imageData = resizedImage.jpegData(compressionQuality: 0.8) {
            UserDefaults.standard.set(imageData, forKey: userDefaultsKey)
        }
        
        // Post notification to refresh any UI displaying the profile image
        NotificationCenter.default.post(
            name: NSNotification.Name("ProfileImageUpdated"),
            object: nil
        )
    }
    
    /// Remove the current profile image
    func removeProfileImage() {
        profileImage = nil
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
        
        // Post notification to refresh any UI displaying the profile image
        NotificationCenter.default.post(
            name: NSNotification.Name("ProfileImageUpdated"),
            object: nil
        )
    }
    
    /// Get user initials from stored name for fallback display
    var userInitials: String? {
        guard let userName = UserDefaults.standard.string(forKey: "userName"),
              !userName.isEmpty else { return nil }
        
        let components = userName.components(separatedBy: " ")
        let initials = components.compactMap { $0.first }.map(String.init)
        
        if initials.count >= 2 {
            return "\(initials[0])\(initials[1])"
        } else if let firstInitial = initials.first {
            return firstInitial
        }
        
        return nil
    }
    
    // MARK: - Helper Methods
    
    private func resizeImage(_ image: UIImage, to size: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
    }
}
