//
//  ImpactView.swift
//  Amped
//
//  Created by Yawar Abbas   on 15/11/2025.
//

import SwiftUI

struct ImpactContentView: View {
    let title: String
    let score: Int
    let maxScore: Int
    let sliderValue: Double
    let descriptionText: String
    let sourceText: String

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            
            // Title
            Text(title)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white.opacity(0.9))
            
            // Score
            (
                Text("\(score)")
                    .foregroundColor(.white)
                    .font(.system(size: 42, weight: .bold))
                +
                Text("/\(maxScore)")
                    .foregroundColor(.white.opacity(0.7))
                    .font(.system(size: 20))
            )
            
            // Slider (non-interactive by default)
            Slider(value: .constant(sliderValue), in: 0...Double(maxScore))
                .tint(.green)
            
            // Description
            Text(descriptionText)
                .foregroundColor(.white.opacity(0.85))
                .font(.system(size: 15))
            
            // Source Button
            Button(action: {}) {
                Text(sourceText)
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.6))
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(8)
            }
        }
    }
}
