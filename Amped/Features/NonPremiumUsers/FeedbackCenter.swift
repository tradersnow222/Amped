import SwiftUI
import Combine

/// Present from anywhere: FeedbackCenter.shared.present()
final class FeedbackCenter: ObservableObject {
    static let shared = FeedbackCenter()
    
    @Published var isPresented: Bool = false
    @Published var text: String = ""
    var title: String = "Please share your feedback with us."
    
    private var onSubmit: ((String) -> Void)?
    private var onCancel: (() -> Void)?
    
    private init() {}
    
    func present(
        title: String = "Please share your feedback with us.",
        prefill: String = "",
        onSubmit: @escaping (String) -> Void,
        onCancel: (() -> Void)? = nil
    ) {
        self.title = title
        self.text = prefill
        self.onSubmit = onSubmit
        self.onCancel = onCancel
        withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
            isPresented = true
        }
    }
    
    func dismiss() {
        withAnimation(.easeInOut(duration: 0.2)) {
            isPresented = false
        }
    }
    
    // Host overlay you can attach once at the root
    @ViewBuilder
    func host<Content: View>(over content: Content) -> some View {
        content
            .overlay(
                Group {
                    if isPresented {
                        Color.black.opacity(0.35)
                            .ignoresSafeArea()
                            .onTapGesture {
                                self.dismiss()
                                self.onCancel?()
                            }
                        FeedbackDialog(
                            title: title,
                            text: Binding(
                                get: { self.text },
                                set: { self.text = $0 }
                            ),
                            onSubmit: { message in
                                self.dismiss()
                                self.onSubmit?(message)
                            },
                            onCancel: {
                                self.dismiss()
                                self.onCancel?()
                            }
                        )
                        .transition(.scale.combined(with: .opacity))
                    }
                }
            )
            .animation(.spring(response: 0.3, dampingFraction: 0.85), value: isPresented)
    }
}
