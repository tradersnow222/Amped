//
//  UnlockSubscriptionView.swift
//  Amped
//
//  Created by Yawar Abbas   on 16/11/2025.
//

import SwiftUI

struct UnlockSubscriptionView: View {
    var buttonText: String = "Unlock metrics by subscribing"
    var action: () -> Void
    
    var body: some View {
        ZStack {
            // Dim background (transparent)
            Color.clear.ignoresSafeArea()

            // Center Button
            Button(action: action) {
                HStack(spacing: 10) {
                    Image(systemName: "lock.open")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text(buttonText)
                        .foregroundColor(.white)
                        .font(.system(size: 18, weight: .semibold))
                }
                .padding(.horizontal, 28)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(
                        colors: [
                            Color.blue.opacity(0.85),
                            Color.green.opacity(0.85)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(Capsule())
                .shadow(color: .black.opacity(0.4), radius: 10, y: 4)
            }
        }
    }
}
