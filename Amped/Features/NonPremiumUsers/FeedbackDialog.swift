import SwiftUI

struct FeedbackDialog: View {
    let title: String
    @Binding var text: String
    let onSubmit: (String) -> Void
    let onCancel: () -> Void
    
    @FocusState private var isFocused: Bool
    
    init(
        title: String = "Please share your feedback with us.",
        text: Binding<String>,
        onSubmit: @escaping (String) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.title = title
        self._text = text
        self.onSubmit = onSubmit
        self.onCancel = onCancel
    }
    
    var body: some View {
        VStack(spacing: 18) {
            // Title
            Text(title)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.vertical, 30)
                .padding(.horizontal, 25)
            
            // TextEditor + placeholder
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.black.opacity(0.2))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
                    .frame(height: 160)
                
                TextEditor(text: $text)
                    .scrollContentBackground(.hidden)
                    .foregroundColor(.white)
                    .tint(.ampedGreen)
                    .padding(12)
                    .frame(height: 160)
                    .focused($isFocused)
                
                if text.isEmpty {
                    Text("Write your feedback")
                        .foregroundColor(.white.opacity(0.45))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 18)
                        .allowsHitTesting(false)
                }
            }
            .padding(.horizontal, 16)
            
            // Done button (brand style)
            Button(action: {
                let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
                onSubmit(trimmed)
            }) {
                Text("Done")
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.black)
            }
            .primaryButtonStyle(isEnabled: !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .padding(.horizontal, 20)
            .hapticFeedback(.medium)
            
            // Not now
            Button(action: {
                onCancel()
            }) {
                Text("Not now")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white.opacity(0.85))
            }
            .padding(.bottom, 25)
            .hapticFeedback()
        }
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 22)
                        .stroke(Color.white.opacity(0.25), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.5), radius: 18, x: 0, y: 10)
        .padding(.horizontal, 28)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                isFocused = true
            }
        }
    }
}
