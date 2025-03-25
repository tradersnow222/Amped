import SwiftUI

/// Extension to help make system backgrounds transparent
/// This is used to remove default system backgrounds from components
/// while maintaining the DeepBackground image throughout the app
extension View {
    /// Makes system background colors transparent to allow background image to show through
    func withTransparentBackground() -> some View {
        self
            .background(Color.clear)
            .listRowBackground(Color.clear)
            .scrollContentBackground(.hidden)
    }
} 