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
    @State private var selectedUnit: WeightUnit = Locale.defaultWeightUnit
    @State private var selectedWeight: Int? = nil
    let progress: Double = 5
    var onContinue: ((String, String) -> Void)?
    var onBack: (() -> Void)?
    
    enum WeightUnit: Int {
        case kg = 0
        case lb = 1
    }
    
    private var isPad: Bool { UIDevice.current.userInterfaceIdiom == .pad }
    private var mascotSize: CGFloat { isPad ? 180 : 120 }
    private var titleSize: CGFloat { isPad ? 34 : 26 }
    private var progressHeight: CGFloat { isPad ? 16 : 12 }
    private var progressTextSize: CGFloat { isPad ? 14 : 12 }
    private var questionFontSize: CGFloat { isPad ? 18 : 16 }
    private var segmentFontSize: CGFloat { isPad ? 16 : 14 }
    private var segmentHeight: CGFloat { isPad ? 52 : 45 }
    private var backIconSize: CGFloat { isPad ? 24 : 20 }
    
    private var weightRange: [Int] {
        selectedUnit == .kg ? Array(30...150) : Array(66...350)
    }
    
    var body: some View {
        ZStack {
            LinearGradient.customBlueToDarkGray
                .ignoresSafeArea()

            VStack(spacing: isPad ? 28 : 24) {
                
                HStack {
                    Button(action: {
                        onBack?()
                    }) {
                        Image("backIcon")
                            .resizable()
                            .scaledToFit()
                            .frame(width: backIconSize, height: backIconSize)
                    }
                    .padding(.leading, 30)
                    .padding(.top, isPad ? 16 : 10)
                    
                    Spacer()
                }
                
                Image("Amped_8")
                    .resizable()
                    .scaledToFit()
                    .frame(width: mascotSize, height: mascotSize)
                    .shadow(color: Color.green.opacity(0.35), radius: isPad ? 18 : 18, x: 0, y: 6)
                    .padding(.top, isPad ? 28 : 25)

                Text("Let's set your stats!")
                    .font(.poppins(titleSize, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.top, 4)

                VStack(spacing: 4) {
                    ProgressView(value: progress, total: 13)
                        .progressViewStyle(ThickProgressViewStyle(height: progressHeight))
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, isPad ? 60 : 40)
                    
                    Text("30%")
                        .font(.poppins(progressTextSize))
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(.bottom, isPad ? 28 : 30)

                VStack(spacing: 8) {
                    Text("Enter your weight to complete your charge profile.")
                        .font(.poppins(isPad ? 18 : 16, weight: .medium))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .truncationMode(.tail)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, isPad ? 60 : 40)
                }
                .padding(.top, 8)

                HStack(spacing: 0) {
                    Button(action: {
                        selectedUnit = .kg
                        selectedWeight = 55
                    }) {
                        Text("KG")
                            .font(.poppins(segmentFontSize, weight: .medium))
                            .foregroundColor(selectedUnit == .kg ? .white : .white.opacity(0.8))
                            .frame(maxWidth: .infinity)
                            .frame(height: segmentHeight)
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

                    Button(action: {
                        selectedUnit = .lb
                        selectedWeight = 121
                    }) {
                        Text("LB")
                            .font(.poppins(segmentFontSize, weight: .medium))
                            .foregroundColor(selectedUnit == .lb ? .white : .white.opacity(0.8))
                            .frame(maxWidth: .infinity)
                            .frame(height: segmentHeight)
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

                WeightPickerView(selectedWeight: $selectedWeight, weightRange: weightRange)
                    .frame(height: isPad ? 150 : 120)
                    .padding(.top, 6)

                OnboardingContinueButton(
                    title: "Continue",
                    isEnabled: selectedWeight != nil,
                    animateIn: true,
                    bottomPadding: isPad ? 50 : 40
                ) {
                    guard let weight = selectedWeight else { return }
                    
                    let weightInKg: Int
                    if selectedUnit == .lb {
                        let kg = Double(weight) * 0.45359237
                        weightInKg = Int((kg).rounded())
                    } else {
                        weightInKg = weight
                    }
                    
                    onContinue?("\(weightInKg)", "KG")
                }
                Spacer()
            }
        }
        .navigationBarBackButtonHidden(false)
        .onAppear {
            if isFromSettings {
                let saved = appState.getFromUserDefault(key: UserDefaultsKeys.userWeight)
                if !saved.isEmpty {
                    selectedWeight = Int(saved)
                }
            }
            
            if selectedWeight == nil {
                selectedWeight = (selectedUnit == .kg) ? 55 : 121
            }
        }
    }
}

struct WeightPickerView: View {
    @Binding var selectedWeight: Int?
    let weightRange: [Int]
    
    private var isPad: Bool { UIDevice.current.userInterfaceIdiom == .pad }
    private var itemSpacing: CGFloat { isPad ? 18 : 14 }
    private var itemSize: CGFloat { isPad ? 120 : 100 }
    private var selectedFontSize: CGFloat { isPad ? 52 : 44 }
    private var unselectedFontSize: CGFloat { isPad ? 26 : 22 }
    
    @State private var itemCenters: [Int: CGFloat] = [:]
    @State private var isDragging = false
    @State private var decelerationSnapWorkItem1: DispatchWorkItem?
    @State private var decelerationSnapWorkItem2: DispatchWorkItem?
    
    var body: some View {
        GeometryReader { geometry in
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: itemSpacing) {
                        Color.clear
                            .frame(width: (geometry.size.width - itemSize) / 2)
                        
                        ForEach(weightRange, id: \.self) { weight in
                            Button(action: {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                    selectedWeight = weight
                                }
                            }) {
                                ZStack {
                                    if selectedWeight == weight {
                                        Circle()
                                            .strokeBorder(Color(hex: "#18EF47").opacity(0.9), lineWidth: 2)
                                            .frame(width: itemSize, height: itemSize)
                                            .shadow(color: Color(hex: "#18EF47").opacity(0.35), radius: 8, x: 0, y: 0)
                                    }
                                    
                                    Text("\(weight)")
                                        .font(.poppins(selectedWeight == weight ? selectedFontSize : unselectedFontSize, weight: selectedWeight == weight ? .bold : .regular))
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
                            snapToNearestCenter(visibleWidth: geometry.size.width, proxy: proxy)
                            schedulePostDecelerationSnaps(visibleWidth: geometry.size.width, proxy: proxy)
                        }
                )
                .onAppear {
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

extension Locale {
    static var usesMetric: Bool {
        Locale.current.usesMetricSystem
    }
    
    static var defaultHeightUnit: HeightStatsView.HeightUnit {
        usesMetric ? .cm : .feet
    }
    
    static var defaultWeightUnit: WeightStatsView.WeightUnit {
        usesMetric ? .kg : .lb
    }
}
