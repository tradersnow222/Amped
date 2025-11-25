//
//  AmpedAnimatedView.swift
//  Amped
//
//  Created by Sheraz Hussain on 21/11/2025.
//

import SwiftUI
import UIKit

struct AmpedAnimatedView: View {

    // Preload all frames once to avoid reload/flicker
    private let frames: [UIImage]
    private let fps: Double
    private let size: CGSize

    /// - Parameters:
    ///   - frameCount: Number of frames named "Amped_0"..."Amped_(frameCount-1)"
    ///   - fps: Frames per second for playback
    ///   - size: Render size for the animation
    init(frameCount: Int = 9, fps: Double = 2, size: CGSize = .init(width: 180, height: 180)) {
        self.fps = fps
        self.size = size
        self.frames = (0..<frameCount).compactMap { UIImage(named: "Amped_\($0)") }
    }

    var body: some View {
        TimelineView(.animation) { context in
            let elapsed = context.date.timeIntervalSinceReferenceDate
            let index = nextFrameIndex(elapsed: elapsed)

            Group {
                if let frame = frame(at: index) {
                    Image(uiImage: frame)
                        .resizable()
                        .scaledToFit()
                        .frame(width: size.width, height: size.height)
                        .animation(nil, value: index) // prevent implicit crossfade
                        .transition(.identity)         // no transition between frames
                } else {
                    // Fallback (in case assets are missing)
                    Color.clear
                        .frame(width: size.width, height: size.height)
                }
            }
        }
    }

    // MARK: - Helpers

    private func nextFrameIndex(elapsed: TimeInterval) -> Int {
        guard !frames.isEmpty else { return 0 }
        let frame = Int(floor(elapsed * fps)) % frames.count
        return frame
    }

    private func frame(at index: Int) -> UIImage? {
        guard frames.indices.contains(index) else { return nil }
        return frames[index]
    }
}
