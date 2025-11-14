//
//  BottomSheetView.swift
//  Amped
//
//  Created by Yawar Abbas   on 15/11/2025.
//

import SwiftUI

struct BottomSheet<Content: View>: View {
    @Binding var isPresented: Bool
    var maxHeight: CGFloat = UIScreen.main.bounds.height * 0.55
    var content: Content
    
    @GestureState private var dragOffset: CGFloat = 0
    
    init(isPresented: Binding<Bool>,
         maxHeight: CGFloat = UIScreen.main.bounds.height * 0.55,
         @ViewBuilder content: () -> Content) {
        self._isPresented = isPresented
        self.maxHeight = maxHeight
        self.content = content()
    }
    
    var body: some View {
        if isPresented {
            ZStack(alignment: .bottom) {
                
                /// Background dimming
                Color.black.opacity(0.35)
                    .ignoresSafeArea()
                    .onTapGesture { isPresented = false }
                
                /// Sheet
                VStack(spacing: 16) {
                    
                    /// Drag indicator
                    RoundedRectangle(cornerRadius: 3)
                        .frame(width: 40, height: 5)
                        .foregroundColor(Color.gray.opacity(0.4))
                        .padding(.top, 8)
                    
                    /// Close button
                    HStack {
                        Spacer()
                        Button(action: { isPresented = false }) {
                            Image(systemName: "xmark")
                                .foregroundColor(.white.opacity(0.8))
                                .padding(12)
                        }
                    }
                    .padding(.trailing, 8)
                    
                    /// Main content
                    ScrollView {
                        content
                            .padding(.horizontal, 20)
                            .padding(.bottom, 20)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: maxHeight)
                .background(Color.black.opacity(0.95))
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .offset(y: dragOffset)
                .gesture(
                    DragGesture().updating($dragOffset) { value, state, _ in
                        if value.translation.height > 0 {
                            state = value.translation.height
                        }
                    }
                    .onEnded { value in
                        if value.translation.height > 120 {
                            isPresented = false
                        }
                    }
                )
                .transition(.move(edge: .bottom))
                .animation(.spring(), value: isPresented)
            }
        }
    }
}
