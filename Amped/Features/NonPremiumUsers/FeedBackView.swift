//
//  FeedBackView.swift
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
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background Color
                Color(red: 0.1, green: 0.12, blue: 0.15)
                    .ignoresSafeArea()
                
                VStack(spacing: 25) {
                    
                    // 1. Mascot Image
                    // Replace "batteryMascot" with the name of your image asset
                    Image(systemName: "battery.100.bolt.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.green)
                        .padding(.top, 20)
                    
                    // 2. Headings
                    Text("Rate Your Experience")
                        .font(.largeTitle.bold())
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
                        Text("Feedback")
                            .font(.headline)
                            .foregroundColor(.white)
                        
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
                                Text("Write your feedback")
                                    .foregroundColor(.gray.opacity(0.7))
                                    .padding(.horizontal, 13)
                                    .padding(.vertical, 16)
                                    .allowsHitTesting(false)
                            }
                        }
                    }
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
            }
            // Navigation Bar Setup
            .navigationTitle("Rate the App")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(Color(red: 0.1, green: 0.12, blue: 0.15), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        presentationMode.wrappedValue.dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.white)
                    }
                }
            }
        }
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
        if rating >= 4 {
            // This just ASKS iOS to show the prompt.
            // Apple decides if and when to actually show it.
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
