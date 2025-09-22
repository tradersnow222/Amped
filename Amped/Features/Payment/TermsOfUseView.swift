//
//  TermsOfUseView.swift
//  Amped
//
//  Created by Assistant on 9/22/2025.
//

import SwiftUI

/// Terms of Use view displaying the app's terms and conditions
struct TermsOfUseView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Terms of Use")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    .padding(.bottom, 10)
                    
                    // Introduction
                    Text("Welcome to Amped! These Terms of Use (\"Terms\") govern your access to and use of the Amped mobile application (\"App\"), operated by Amped (\"Company\", \"we\", \"our\", or \"us\"). By downloading, accessing, or using the App, you agree to be bound by these Terms. If you do not agree, please do not use the App.")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.white)
                        .lineSpacing(4)
                    
                    // Terms sections
                    TermsSection(
                        number: "1",
                        title: "Eligibility",
                        content: "You must be at least 13 years old to use Amped. By using the App, you confirm that the information you provide (including name, age, gender, and habit-related responses) is accurate and truthful."
                    )
                    
                    TermsSection(
                        number: "2",
                        title: "Free Trial and Subscriptions",
                        content: "• Amped offers a 3-day free trial to new users.\n• After the trial, continued access requires a monthly subscription of USD $4.99.\n• Subscriptions automatically renew unless canceled at least 24 hours before the renewal date.\n• Payment will be charged to your app store account"
                    )
                    
                    TermsSection(
                        number: "3",
                        title: "User Responsibilities",
                        content: "You agree not to misuse the App, including but not limited to:\n• Providing false or misleading information.\n• Attempting to disrupt or hack the App.\n• Using the App in violation of applicable laws."
                    )
                    
                    TermsSection(
                        number: "4",
                        title: "Intellectual Property",
                        content: "All content, designs, code, and features of Amped remain the property of the Company. You may not copy, modify, distribute, or resell any part of the App without prior written consent."
                    )
                    
                    TermsSection(
                        number: "5",
                        title: "Termination",
                        content: "We may suspend or terminate your access to Amped if you violate these Terms. You may also cancel your subscription at any time via your app store account."
                    )
                    
                    TermsSection(
                        number: "6",
                        title: "Limitation of Liability",
                        content: "Amped is provided \"as is\" without warranties of any kind. We are not liable for any damages resulting from your use of the App."
                    )
                    
                    TermsSection(
                        number: "7",
                        title: "Changes to Terms",
                        content: "We reserve the right to update these Terms at any time. Continued use after updates constitutes acceptance of the revised Terms."
                    )
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 20)
            }
            .background(Color.black)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.ampedGreen)
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

/// Individual terms section component
private struct TermsSection: View {
    let number: String
    let title: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("\(number). \(title)")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            BulletListText(content: content)
        }
    }
}

/// Custom text view that handles bullet point formatting with hanging indent
private struct BulletListText: View {
    let content: String
    
    var body: some View {
        let lines = content.components(separatedBy: "\n")
        
        VStack(alignment: .leading, spacing: 4) {
            ForEach(Array(lines.enumerated()), id: \.offset) { index, line in
                if line.hasPrefix("•") {
                    BulletLine(text: String(line.dropFirst(2))) // Remove "• "
                } else if !line.isEmpty {
                    Text(line)
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.white)
                        .lineSpacing(4)
                }
            }
        }
    }
}

/// Single bullet point line with hanging indent
private struct BulletLine: View {
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(.white)
                .frame(width: 8, alignment: .leading)
            
            Text(text)
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(.white)
                .lineSpacing(4)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - Preview

#Preview {
    TermsOfUseView()
        .preferredColorScheme(.dark)
}
