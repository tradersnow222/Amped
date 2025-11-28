//
//  TermsView.swift
//  Amped
//
//  Created by Yawar Abbas   on 15/11/2025.
//

import SwiftUI

struct TermsView: View {
    
    var onContinue: (() -> Void)?
    var onBack: (() -> Void)?
    
    // Condensed copy (kept same content, shown in compact layout)
    let termString = """
    Effective Date: 28 October, 2025
    Company: Amped

    Welcome to Amped! These Terms of Use (“Terms”) govern your access to and use of the Amped mobile application (“App”), operated by Amped (“Company”, “we”, “our”, or “us”). By downloading, accessing, or using the App, you agree to be bound by these Terms. If you do not agree, please do not use the App.

    1. Eligibility
    You must be at least 13 years old to use Amped. By using the App, you confirm that the information you provide (including name, age, gender, and habit-related responses) is accurate and truthful.

    2. Free Trial and Subscriptions
    Amped offers a 3-day free trial to new users. After the trial, continued access requires a monthly subscription of USD $4.99 or an annual subscription of USD $29.99. Subscriptions automatically renew unless canceled at least 24 hours before the renewal date. Payment will be charged to your app store account.

    3. User Responsibilities
    You agree not to misuse the App, including but not limited to: providing false or misleading information, attempting to disrupt or hack the App, or using the App in violation of applicable laws.

    4. Intellectual Property
    All content, designs, code, and features of Amped remain the property of the Company. You may not copy, modify, distribute, or resell any part of the App without prior written consent.

    5. Termination
    We may suspend or terminate your access to Amped if you violate these Terms. You may also cancel your subscription at any time via your app store account.

    6. Limitation of Liability
    Amped is provided “as is” without warranties of any kind. We are not liable for any damages resulting from your use of the App.

    7. Changes to Terms
    We reserve the right to update these Terms at any time. Continued use after updates constitutes acceptance of the revised Terms.
    """
    
    var body: some View {
        ZStack {
            // Use the parent black background from OnboardingFlow for consistency
            Color.clear.ignoresSafeArea()
            
            VStack(spacing: 16) {
                // Minimal header
                HStack {
                    Button(action: { onBack?() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white.opacity(0.9))
                            .padding(8)
                            .background(Color.white.opacity(0.08))
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                    
                    Text("Terms of Use")
                        .font(.poppins(18, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    // Spacer to balance the back button
                    Color.clear
                        .frame(width: 33, height: 33)
                        .accessibilityHidden(true)
                }
                
                // Condensed, scrollable terms
                ScrollView {
                    Text(highlight(
                        termString,
                        words: [
                            "1. Eligibility",
                            "2. Free Trial and Subscriptions",
                            "3. User Responsibilities",
                            "4. Intellectual Property",
                            "5. Termination",
                            "6. Limitation of Liability",
                            "7. Changes to Terms"
                        ],
                        color: .ampedGreen
                    ))
                    .font(.poppins(13, weight: .regular))
                    .foregroundColor(.white.opacity(0.85))
                    .multilineTextAlignment(.leading)
                    .lineSpacing(5)
                    .padding(.top, 2)
                }
//                .frame(maxHeight: 360) // keep it compact
                .scrollIndicators(.visible)
                
                Spacer()
                
                // Primary action
                OnboardingContinueButton(
                    title: "Agree & Continue",
                    isEnabled: true,
                    animateIn: true,
                    bottomPadding: 0
                ) {
                    onContinue?()
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 20)
//            .frame(maxWidth: 600) // smaller on large screens
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.black.opacity(0.55))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
            )
            .padding(.horizontal, 16)
        }
    }
    
    func highlight(_ full: String, words: [String], color: Color = .blue) -> AttributedString {
        var text = AttributedString(full)

        for word in words {
            if let range = text.range(of: word) {
                text[range].foregroundColor = color
                text[range].font = .poppins(14, weight: .semibold)
            }
        }
        return text
    }
}

#Preview {
    TermsView()
}
