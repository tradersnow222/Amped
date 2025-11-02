import SwiftUI

/// Before/After transformation screen showing the journey from basic to enhanced health tracking
struct BeforeAfterTransformationView: View {
    // MARK: - Properties
    
    @State private var animateElements = false
    
    // Callback to proceed to next step
    var onContinue: (() -> Void)?
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            
            Image("femaleBg")
                .resizable()
                .scaledToFill()
                .opacity(0.40)
                .ignoresSafeArea()
            
            LinearGradient.ampBlueGradient
                .ignoresSafeArea()
            
            VStack {
                Spacer()
                
                // MARK: Text Content
                VStack(alignment: .leading, spacing: 12) {
                    Text("Powered by \nReal Science, \nNot Guesswork.")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .font(.poppins(40, weight: .bold))
                        .foregroundColor(.white)
                        .shadow(radius: 3)
                        .opacity(animateElements ? 1 : 0)
                        .offset(y: animateElements ? 0 : 40)
                        .animation(.easeOut(duration: 0.8).delay(0.1), value: animateElements)
                        .padding(.leading, 30)
                    
                    
                    Text("Science-backed insights from Harvard \n& AHA on how your habits impact your \nlifespan.")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .font(.poppins(18))
                        .foregroundColor(.white.opacity(0.85))
                        .opacity(animateElements ? 1 : 0)
                        .offset(y: animateElements ? 0 : 40)
                        .animation(.easeOut(duration: 0.8).delay(0.3), value: animateElements)
                        .padding(.leading, 30)
                }
//                .padding(.horizontal, 30)
                .padding(.bottom, 30)
                
                // MARK: Continue Button
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        onContinue?()
                    }
                }) {
                    HStack {
                        Text("Get Started")
                            .font(.poppins(20, weight: .medium))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 17, weight: .semibold))
                            
                    }
                    .foregroundColor(.black)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(LinearGradient.ampButtonGradient)
                    .cornerRadius(30)
                    .padding(.horizontal, 30)
                    .shadow(color: Color.black.opacity(0.3), radius: 5, x: 0, y: 3)
                    .opacity(animateElements ? 1 : 0)
                    .offset(y: animateElements ? 0 : 50)
                    .scaleEffect(animateElements ? 1 : 0.9)
                    .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.6), value: animateElements)
                }
                .padding(.bottom, 50)
            }
        }
        .onAppear {
            // Trigger animation when the view appears
            animateElements = true
        }
    }
}

// MARK: - Preview

struct BeforeAfterTransformationView_Previews: PreviewProvider {
    static var previews: some View {
        BeforeAfterTransformationView(onContinue: {})
            .preferredColorScheme(.dark)
    }
}
