//
//  BatteryFillFramesView.swift
//  Amped
//
//  Created by Sheraz Hussain on 29/11/2025.
//

import SwiftUI

// MARK: - Battery fill frames animator
struct BatteryFillFramesView: View {
    let level: Double   // 0.0 ... 1.0
    let size: CGFloat
    
    @State private var currentFrame: Int = 0
    @State private var animTimer: Timer?
    
    private let minFrame = 0
    private let maxFrame = 6
    private let frameNames = (0...6).map { "amped_battery_\($0)" }
    private let frameStepInterval: TimeInterval = 0.3
    
    private var targetFrame: Int {
        // Round to nearest frame based on level
        let idx = Int(round(level * Double(maxFrame)))
        return max(minFrame, min(maxFrame, idx))
    }
    
    var body: some View {
        Image(frameNames[clamp(currentFrame, minFrame, maxFrame)])
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: size, height: size)
            .onAppear {
                // Start at neutral when first shown
                currentFrame = 3
                animateTo(targetFrame)
            }
            .onChange(of: level) { _ in
                animateTo(targetFrame)
            }
    }
    
    private func animateTo(_ newTarget: Int) {
        animTimer?.invalidate()
        guard newTarget != currentFrame else { return }
        
        let ascending = newTarget > currentFrame
        animTimer = Timer.scheduledTimer(withTimeInterval: frameStepInterval, repeats: true) { timer in
            if ascending {
                currentFrame += 1
            } else {
                currentFrame -= 1
            }
            
            if currentFrame == newTarget {
                timer.invalidate()
                animTimer = nil
            }
        }
        if let t = animTimer {
            RunLoop.main.add(t, forMode: .common)
        }
    }
    
    private func clamp(_ value: Int, _ minV: Int, _ maxV: Int) -> Int {
        return max(minV, min(maxV, value))
    }
}
