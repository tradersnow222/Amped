import SwiftUI

/// Consistent back button component used throughout the app
/// Rules: Simplicity is KING - keeping this component simple and reusable
struct BackButton: View {
    // MARK: - Properties
    
    /// Action to perform when button is tapped
    let action: () -> Void
    
    /// Optional custom text (defaults to "Back")
    let text: String?
    
    /// Whether to show text alongside the chevron
    let showText: Bool
    
    // MARK: - Initializers
    
    init(action: @escaping () -> Void, text: String? = nil, showText: Bool = true) {
        self.action = action
        self.text = text
        self.showText = showText
    }
    
    // MARK: - Body
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                
                if showText {
                    Text(text ?? "Back")
                        .font(.system(size: 16, weight: .regular))
                }
            }
            .foregroundColor(.ampedGreen)
            .padding(.vertical, 10)
            .padding(.horizontal, 16)
        }
        .accessibilityLabel(showText ? "Go back to \(text ?? "previous")" : "Go back")
        .hapticFeedback()
    }
}

// MARK: - Convenience Extensions

extension View {
    /// Adds a back button to the view with consistent styling
    func withBackButton(action: @escaping () -> Void, text: String? = nil, showText: Bool = true) -> some View {
        VStack(spacing: 0) {
            HStack {
                BackButton(action: action, text: text, showText: showText)
                Spacer()
            }
            .padding(.top, 16)
            .padding(.leading, 8)
            
            self
        }
    }
}

// MARK: - Preview

#if DEBUG
struct BackButton_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            BackButton(action: { print("Back tapped") })
            
            BackButton(action: { print("Back tapped") }, text: "Previous", showText: true)
            
            BackButton(action: { print("Back tapped") }, showText: false)
        }
        .padding()
        .background(Color.black)
    }
}
#endif 