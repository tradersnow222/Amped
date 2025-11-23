//
//  WeightStatsView.swift
//  Amped
//
//  Created by Yawar Abbas   on 03/11/2025.
//

import SwiftUI

private struct ItemCenterPreferenceKey: PreferenceKey {
    static var defaultValue: [Int: CGFloat] = [:]
    static func reduce(value: inout [Int : CGFloat], nextValue: () -> [Int : CGFloat]) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}

struct WeightStatsView: View {
    @EnvironmentObject private var appState: AppState

    var isFromSettings: Bool = false
    @State private var selectedUnit: WeightUnit = .kg
    // Default to 55 as requested
    @State private var selectedWeight: Int? = 55
    let progress: Double = 5
    var onContinue: ((String, String) -> Void)?
    var onBack: (() -> Void)?
    
    enum WeightUnit: Int {
        case kg = 0
        case lb = 1
    }
    
    // Weight range based on unit
    private var weightRange: [Int] {
        selectedUnit == .kg ? Array(30...150) : Array(66...350)
    }
    
    var body: some View {
        ZStack {
            LinearGradient.customBlueToDarkGray
                .ignoresSafeArea()

            VStack(spacing: 24) {
                
                HStack {
                    Button(action: {
                        // back action
                        onBack?()
                    }) {
                        Image("backIcon")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                    }
                    .padding(.leading, 30)
                    .padding(.top, 10)
                    
                    Spacer() // pushes button to leading
                }
                
                // Top mascot image
                Image("battery")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .shadow(color: Color.green.opacity(0.35), radius: 18, x: 0, y: 6)
                    .padding(.top, 25)

                Text("Let's set your stats!")
                    .font(.poppins(26, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.top, 4)

                // MARK: - Progress Bar
                VStack(spacing: 4) {
                    ProgressView(value: progress, total: 13)
                        .progressViewStyle(ThickProgressViewStyle(height: 12))
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 40)
                    
                    Text("30%")
                        .font(.poppins(12))
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(.bottom, 30)

                VStack(spacing: 8) {
                    Text("Enter your weight to complete your charge profile.")
                        .font(.poppins(16, weight: .medium))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .truncationMode(.tail)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 40)
                }
                .padding(.top, 8)

                // Segmented unit control
                HStack(spacing: 0) {
                    // KG segment
                    Button(action: {
                        selectedUnit = .kg
                        // Default selection for KG as requested
                        selectedWeight = 55
                    }) {
                        Text("KG")
                            .font(.poppins(14, weight: .medium))
                            .foregroundColor(selectedUnit == .kg ? .white : .white.opacity(0.8))
                            .frame(maxWidth: .infinity)
                            .frame(height: 45)
                            .background(
                                Group {
                                    if selectedUnit == .kg {
                                        LinearGradient(
                                            colors: [Color(hex: "#18EF47"), Color(hex: "#0E8929")],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    } else {
                                        Color.clear
                                    }
                                }
                            )
                    }
                    .frame(maxWidth: .infinity)

                    // LB segment
                    Button(action: {
                        selectedUnit = .lb
                        // Choose a sensible default for LB; convert 55 kg ≈ 121 lb
                        selectedWeight = 121
                    }) {
                        Text("LB")
                            .font(.poppins(14, weight: .medium))
                            .foregroundColor(selectedUnit == .lb ? .white : .white.opacity(0.8))
                            .frame(maxWidth: .infinity)
                            .frame(height: 45)
                            .background(
                                Group {
                                    if selectedUnit == .lb {
                                        LinearGradient(
                                            colors: [Color(hex: "#18EF47"), Color(hex: "#0E8929")],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    } else {
                                        Color.clear
                                    }
                                }
                            )
                    }
                    .frame(maxWidth: .infinity)
                }
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Color.white.opacity(0.08))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .padding(.horizontal, 32)
                .padding(.top, 4)

                // Horizontal Weight Picker
                WeightPickerView(selectedWeight: $selectedWeight, weightRange: weightRange)
                    .frame(height: 120)
                    .padding(.top, 6)

                OnboardingContinueButton(
                    title: "Continue",
                    isEnabled: selectedWeight != nil,
                    animateIn: true,
                    bottomPadding: 40
                ) {
                    guard let weight = selectedWeight else { return }
                    
                    // Normalize to KG for saving/calculation
                    let weightInKg: Int
                    if selectedUnit == .lb {
                        let kg = Double(weight) * 0.45359237
                        weightInKg = Int((kg).rounded()) // round to nearest whole kg
                    } else {
                        weightInKg = weight
                    }
                    
                    // Always pass KG as the unit string since we save in kg
                    onContinue?("\(weightInKg)", "KG")
                }
                Spacer()
            }
        }
        .navigationBarBackButtonHidden(false)
        .onAppear {
            // If launched from Settings, prefill from defaults
            if isFromSettings {
                let saved = appState.getFromUserDefault(key: UserDefaultsKeys.userWeight)
                if !saved.isEmpty {
                    selectedWeight = Int(saved)
                }
            }
        }
    }
}

struct WeightPickerView: View {
    @Binding var selectedWeight: Int?
    let weightRange: [Int]
    
    private let itemSpacing: CGFloat = 14
    private let itemSize: CGFloat = 100
    
    @State private var itemCenters: [Int: CGFloat] = [:]
    @State private var isDragging = false
    @State private var decelerationSnapWorkItem1: DispatchWorkItem?
    @State private var decelerationSnapWorkItem2: DispatchWorkItem?
    
    var body: some View {
        GeometryReader { geometry in
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: itemSpacing) {
                        // Leading spacer to center the first item
                        Color.clear
                            .frame(width: (geometry.size.width - itemSize) / 2)
                        
                        ForEach(weightRange, id: \.self) { weight in
                            Button(action: {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                    selectedWeight = weight
                                }
                            }) {
                                ZStack {
                                    // Selected ring
                                    if selectedWeight == weight {
                                        Circle()
                                            .strokeBorder(Color(hex: "#18EF47").opacity(0.9), lineWidth: 2)
                                            .frame(width: itemSize, height: itemSize)
                                            .shadow(color: Color(hex: "#18EF47").opacity(0.35), radius: 8, x: 0, y: 0)
                                    }
                                    
                                    Text("\(weight)")
                                        .font(.poppins(selectedWeight == weight ? 44 : 22, weight: selectedWeight == weight ? .bold : .regular))
                                        .foregroundColor(selectedWeight == weight ? Color(hex: "#18EF47") : .white.opacity(0.45))
                                        .frame(width: itemSize, height: itemSize)
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                            .id(weight)
                            .background(
                                GeometryReader { geo in
                                    Color.clear
                                        .preference(
                                            key: ItemCenterPreferenceKey.self,
                                            value: [weight: geo.frame(in: .named("picker")).midX]
                                        )
                                }
                            )
                        }
                        
                        // Trailing spacer to center the last item
                        Color.clear
                            .frame(width: (geometry.size.width - itemSize) / 2)
                    }
                }
                .coordinateSpace(name: "picker")
                .onPreferenceChange(ItemCenterPreferenceKey.self) { centers in
                    itemCenters = centers
                }
                .simultaneousGesture(
                    DragGesture()
                        .onChanged { _ in
                            isDragging = true
                            cancelScheduledSnaps()
                        }
                        .onEnded { _ in
                            isDragging = false
                            // Immediate snap
                            snapToNearestCenter(visibleWidth: geometry.size.width, proxy: proxy)
                            // Post-deceleration safety snaps (covers inertial scrolling drift)
                            schedulePostDecelerationSnaps(visibleWidth: geometry.size.width, proxy: proxy)
                        }
                )
                .onAppear {
                    // Ensure default selection (55) is visible/centered on first appear
                    if selectedWeight == nil {
                        selectedWeight = 55
                    }
                    if let w = selectedWeight {
                        DispatchQueue.main.async {
                            proxy.scrollTo(w, anchor: .center)
                        }
                    }
                }
                .onChange(of: selectedWeight) { newValue in
                    if let weight = newValue {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                            proxy.scrollTo(weight, anchor: .center)
                        }
                    }
                }
                // If the range changes (e.g., unit switch), ensure we still have a valid selection and center it
                .onChange(of: weightRange) { _ in
                    if let current = selectedWeight, !weightRange.contains(current) {
                        selectedWeight = weightRange.first
                    }
                    if let w = selectedWeight {
                        DispatchQueue.main.async {
                            proxy.scrollTo(w, anchor: .center)
                        }
                    }
                }
            }
        }
    }
    
    private func snapToNearestCenter(visibleWidth: CGFloat, proxy: ScrollViewProxy) {
        let visibleCenterX = visibleWidth / 2.0
        guard !itemCenters.isEmpty else { return }
        
        // Find the value whose center is closest to the visible center
        let nearest = itemCenters.min { a, b in
            abs(a.value - visibleCenterX) < abs(b.value - visibleCenterX)
        }
        
        if let target = nearest?.key {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                selectedWeight = target
                proxy.scrollTo(target, anchor: .center)
            }
        }
    }
    
    private func schedulePostDecelerationSnaps(visibleWidth: CGFloat, proxy: ScrollViewProxy) {
        cancelScheduledSnaps()
        
        let work1 = DispatchWorkItem {
            snapToNearestCenter(visibleWidth: visibleWidth, proxy: proxy)
        }
        let work2 = DispatchWorkItem {
            snapToNearestCenter(visibleWidth: visibleWidth, proxy: proxy)
        }
        decelerationSnapWorkItem1 = work1
        decelerationSnapWorkItem2 = work2
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15, execute: work1)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35, execute: work2)
    }
    
    private func cancelScheduledSnaps() {
        decelerationSnapWorkItem1?.cancel()
        decelerationSnapWorkItem1 = nil
        decelerationSnapWorkItem2?.cancel()
        decelerationSnapWorkItem2 = nil
    }
}

#Preview {
    WeightStatsView()
}
