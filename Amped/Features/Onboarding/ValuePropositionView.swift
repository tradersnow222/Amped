import SwiftUI
import AVFoundation
import AVKit

/// DNA video background player
struct DNAVideoBackgroundView: View {
    @State private var player = AVPlayer()
    
    var body: some View {
        VideoPlayer(player: player)
            .disabled(true) // Disable user interaction
            .onAppear {
                setupVideo()
            }
    }
    
    private func setupVideo() {
        guard let url = Bundle.main.url(forResource: "dna", withExtension: "mov") else {
            print("❌ Could not find dna.mov in bundle")
            return
        }
        
        player = AVPlayer(url: url)
        player.isMuted = true
        player.play()
        
        // Set up looping
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: player.currentItem,
            queue: .main
        ) { _ in
            player.seek(to: .zero)
            player.play()
        }
        
        print("✅ Video player setup complete")
    }
}

/// Value proposition screen explaining how Amped helps users live longer
struct ValuePropositionView: View {
    // MARK: - Properties
    
    @State private var animateElements = false
    
    // Callback to proceed to next step
    var onContinue: (() -> Void)?
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // Background video with overlay
            GeometryReader { geometry in
                DNAVideoBackgroundView()
                    .frame(width: geometry.size.width, height: geometry.size.height, alignment: .top)
                    .rotationEffect(.degrees(90)) // Rotate 90 degrees
                    .scaleEffect(1.8) // Increased scale for wider coverage
                    .offset(y: -180) // Match the original image offset
                    .clipped()
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                
                // Linear gradient overlay matching exact specifications
                LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: Color(red: 102/255, green: 102/255, blue: 102/255).opacity(0.0), location: 0.0),     // rgba(102, 102, 102, 0) at 0%
                        .init(color: Color(red: 51/255, green: 51/255, blue: 51/255).opacity(0.5), location: 0.3894),     // rgba(51, 51, 51, 0.5) at 38.94%
                        .init(color: Color.black, location: 0.6635)                                                      // #000000 at 66.35%
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            .edgesIgnoringSafeArea(.all)
            
            // Main content
            VStack(spacing: 48) {
                Spacer()
                VStack(spacing: 0){
                    // Heart icon at top
                    Image("heart")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 24, height: 24)
                        .opacity(animateElements ? 1 : 0)
                        .scaleEffect(animateElements ? 1 : 0.8)
                        .animation(.easeOut(duration: 0.8), value: animateElements)
                    
                    // Main headline
                    VStack(spacing:0){
                        Text("Welcome to Amped")
                            .font(.system(size: 32, weight: .bold, design: .default))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .padding(.top, 4)
                            .opacity(animateElements ? 1 : 0)
                            .offset(y: animateElements ? 4 : 20)
                            .animation(.easeOut(duration: 0.8).delay(0.2), value: animateElements)
                        
                        // Text("Your Life")
                        //     .font(.system(size: 32, weight: .bold, design: .default))
                        //     .foregroundColor(.white)
                        //     .multilineTextAlignment(.center)
                        //     .opacity(animateElements ? 1 : 0)
                        //     .offset(y: animateElements ? 0 : 20)
                        //     .padding(.top,4)
                        //     .animation(.easeOut(duration: 0.8).delay(0.2), value: animateElements)
                    }
                    // Subtitle
                    Text("Life is short, but we're here to help you live as long as possible.")
                        .font(.system(size: 22, weight: .light, design: .default))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.horizontal, 28)
                        .padding(.top, 16)
                        .opacity(animateElements ? 1 : 0)
                        .offset(y: animateElements ? 0 : 20)
                        .animation(.easeOut(duration: 0.8).delay(0.4), value: animateElements)
                    // Feature highlights
                    HStack(spacing:25) {
                        featureHighlight(
                            iconName: "heartline",
                            title: "Track lifespan",
                            delay: 0.6
                        )
                        
                        featureHighlight(
                            iconName: "liveupdates",
                            title: "Improve habits",
                            delay: 0.7
                        )
                        
                        featureHighlight(
                            iconName: "records",
                            title: "Live longer",
                            delay: 0.8
                        )
                    }
                    .padding(.top, 40)
                    
                }
                // Get Started button
                Button(action: {
                    onContinue?()
                }) {
                    Text("Get Started")
                }
                .primaryButtonStyle()
                .padding(.horizontal, 28)
                .opacity(animateElements ? 1 : 0)
                .scaleEffect(animateElements ? 1 : 0.9)
                .animation(.easeOut(duration: 0.8).delay(1.0), value: animateElements)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            withAnimation {
                animateElements = true
            }
        }
    }
    
    // MARK: - Subviews
    
    private func featureHighlight(iconName: String, title: String, delay: Double) -> some View {
        HStack(spacing: 6) {
            // Icon
            Image(iconName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 20, height: 20)
                .foregroundColor(.white)
            
            // Title
            Text(title)
                .font(.system(size: 13, weight: .regular, design: .default))
                .foregroundColor(.white)
            
        }
        .opacity(animateElements ? 1 : 0)
        .offset(x: animateElements ? 0 : -20)
        .animation(.easeOut(duration: 0.8).delay(delay), value: animateElements)
    }
}

// MARK: - Preview

struct ValuePropositionView_Previews: PreviewProvider {
    static var previews: some View {
        ValuePropositionView(onContinue: {})
            .preferredColorScheme(.dark)
    }
} 
