//
//  AmpedAnimatedView.swift
//  Amped
//
//  Created by Sheraz Hussain on 21/11/2025.
//

import SwiftUI

struct AmpedAnimatedView: View {

    @State private var frameIndex = 0

    private let timer = Timer.publish(every: 0.32, on: .main, in: .common).autoconnect()

    var body: some View {
        Image("Amped_\(frameIndex)")
            .resizable()
            .scaledToFit()
            .frame(width: 200, height: 200)
            .onReceive(timer) { _ in
                withAnimation(.linear(duration: 0.2)) {
                    frameIndex = (frameIndex + 1) % 9
                }
            }
    }
}
