import SwiftUI

struct SplashView: View {
    var duration: TimeInterval = 3
    var onFinish: () -> Void

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea(.all)
            LinearGradient.customBlueToDarkGray
                .ignoresSafeArea()

            // Centered animated mascot
            AmpedAnimatedView(frameCount: 9, fps: 2, size: .init(width: 180, height: 180))
        }
        .onAppear {
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(duration))
                onFinish()
            }
        }
    }
}

#Preview {
    SplashView {
        // no-op
    }
}
