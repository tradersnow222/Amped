//
//  RateAppView.swift
//  Amped
//
//  Created by Yawar Abbas   on 16/11/2025.
//
import SwiftUI
import StoreKit // Import this to ask for a review

struct RateAppView: View {
    
    // MARK: - State Variables
    
    // Holds the user's star rating (1-5)
    @State private var rating: Int = 0
    
    // Holds the text from the feedback box
    @State private var feedbackText: String = ""
    
    // Access the modern 'requestReview' action
    @Environment(\.requestReview) var requestReview
    
    // Used to dismiss the screen
    @Environment(\.presentationMode) var presentationMode
    
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Body
    
    var body: some View {
            ZStack {
                // Full-screen background gradient
                LinearGradient.customBlueToDarkGray
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    
                    header
                    
                    ScrollView {
                        VStack(spacing: 25) {
                            // 1. Mascot Image
                            // Replace "batteryMascot" with the name of your image asset
                            Image("battery")
                                .font(.system(size: 80))
                                .foregroundColor(.green)
                                .padding(.top, 20)
                            
                            // 2. Headings
                            Text("Rate Your Experience")
                                .font(.system(size: 35).weight(.bold))
                                .foregroundColor(.white)
                            
                            Text("We are working hard for better user experience. We'd greatly appreciate if you could rate us.")
                                .font(.callout)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                            
                            // 3. Star Rating
                            HStack(spacing: 15) {
                                ForEach(1...5, id: \.self) { index in
                                    Image(systemName: index <= rating ? "star.fill" : "star")
                                        .font(.system(size: 35))
                                        .foregroundColor(.yellow)
                                        .onTapGesture {
                                            rating = index
                                        }
                                }
                            }
                            
                            // 4. Feedback Section
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Spacer()
                                    Text("Feedback")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                    Spacer()
                                }
                                
                                // TextEditor with placeholder
                                ZStack(alignment: .topLeading) {
                                    TextEditor(text: $feedbackText)
                                        .scrollContentBackground(.hidden) // Makes it transparent
                                        .padding(8)
                                        .frame(height: 150)
                                        .background(Color.black.opacity(0.2))
                                        .cornerRadius(10)
                                        .foregroundColor(.white)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(Color.green.opacity(0.8), lineWidth: 1)
                                        )
                                    
                                    // Placeholder logic
                                    if feedbackText.isEmpty {
                                        HStack {
                                            Spacer()
                                            Text("Write your feedback")
                                                .foregroundColor(.gray.opacity(0.7))
                                                .padding(.horizontal, 13)
                                                .padding(.vertical, 16)
                                                .allowsHitTesting(false)
                                            Spacer()
                                        }
                                    }
                                }
                            }
                            .padding(.top)
                            .padding(.horizontal)
                            
                            Spacer() // Pushes the button to the bottom
                            
                            // 5. Save Button
                            Button(action: handleSave) {
                                Text("Save")
                                    .font(.headline.bold())
                                    .foregroundColor(.black)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.green)
                                    .cornerRadius(25)
                            }
                            .padding(.horizontal)
                            .padding(.bottom)
                        }
                        .padding(.top)
                    }
                    .scrollDismissesKeyboard(.interactively)
                }
            }
            .navigationBarHidden(true)
    }
    
    private var header: some View {
        ZStack {
            HStack {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .foregroundStyle(.white)
                        .font(.system(size: 20, weight: .semibold))
                        .padding(12)
                }
                Spacer()
            }
            
            Text("Rate the App")
                .foregroundStyle(.white)
                .font(.system(size: 18, weight: .semibold))
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 12)
    }
    
    // MARK: - Action Handler
    
    func handleSave() {
        // --- THIS IS THE IMPORTANT PART ---
        
        // **Step 1: Save the feedback for YOURSELF**
        // You CANNOT send this text and rating to the App Store.
        // Instead, save it to your own database (like Firebase, Supabase, or your own API)
        // so you can read it and improve your app.
        print("--- Feedback Collected ---")
        print("Rating: \(rating) stars")
        print("Feedback: \(feedbackText)")
        print("--------------------------")
        // (Add your code here to send this data to your server)
        
        
        // **Step 2: If the rating is good, ask for an App Store review**
        // This opens the standard Apple review prompt.
        // It does NOT use the feedback text or star rating you just collected.
        if rating <= 3 {
            // Send feedback via email
            let body = """
            Rating: \(rating)
            Message:
            \(feedbackText)
            """
            FeedbackEmailHelper.shared.sendFeedbackEmail(body: body)
        } else {
            requestReview()
        }
        
        // **Step 3: Close the screen**
        presentationMode.wrappedValue.dismiss()
    }
}

// MARK: - Preview

#Preview {
    RateAppView()
}
