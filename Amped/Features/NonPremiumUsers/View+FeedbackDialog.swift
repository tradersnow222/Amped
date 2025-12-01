import SwiftUI

extension View {
    /// Overlay a reusable feedback dialog.
    /// - Parameters:
    ///   - isPresented: Bind to control presentation.
    ///   - text: Bind to capture text.
    ///   - title: Optional custom title.
    ///   - onSubmit: Called with text when Done is tapped.
    ///   - onCancel: Called when Not now is tapped or background is dismissed.
    func feedbackDialog(
        isPresented: Binding<Bool>,
        text: Binding<String>,
        title: String = "Please share your feedback with us.",
        onSubmit: @escaping (String) -> Void,
        onCancel: @escaping () -> Void
    ) -> some View {
        ZStack {
            self
            
            if isPresented.wrappedValue {
                // Dimmed blur background
                Color.black.opacity(0.35)
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isPresented.wrappedValue = false
                        }
                        onCancel()
                    }
                
                // Centered dialog
                FeedbackDialog(
                    title: title,
                    text: text,
                    onSubmit: { message in
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isPresented.wrappedValue = false
                        }
                        onSubmit(message)
                    },
                    onCancel: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isPresented.wrappedValue = false
                        }
                        onCancel()
                    }
                )
                .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.85), value: isPresented.wrappedValue)
    }
}
