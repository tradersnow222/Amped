//
//  HeightStatsView.swift
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

struct HeightStatsView: View {
    @EnvironmentObject private var appState: AppState

    var isFromSettings: Bool = false
    @State private var selectedUnit: HeightUnit = Locale.defaultHeightUnit
    
    @State private var selectedHeight: Int? = nil
    let progress: Double = 4
    var onContinue: ((String) -> Void)?
    var onBack: (() -> Void)?
    
    enum HeightUnit: Int {
        case feet = 0
        case cm = 1
    }
    
    private var isPad: Bool { UIDevice.current.userInterfaceIdiom == .pad }
    private var mascotSize: CGFloat { isPad ? 180 : 120 }
    private var titleSize: CGFloat { isPad ? 34 : 26 }
    private var progressHeight: CGFloat { isPad ? 16 : 12 }
    private var progressTextSize: CGFloat { isPad ? 14 : 12 }
    private var questionFontSize: CGFloat { isPad ? 22 : 18 }
    private var segmentFontSize: CGFloat { isPad ? 16 : 14 }
    private var segmentHeight: CGFloat { isPad ? 52 : 45 }
    private var backIconSize: CGFloat { isPad ? 24 : 20 }

    private var heightRange: [Int] {
        switch selectedUnit {
        case .cm:
            return Array(120...220)
        case .feet:
            return Array(48...84)
        }
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
                    
                    Text("23%")
                        .font(.poppins(progressTextSize))
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(.bottom, isPad ? 28 : 30)

                Text("How tall are you?")
                    .font(.poppins(questionFontSize, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.top, 8)

                HStack(spacing: 0) {
                    Button(action: {
                        selectedUnit = .feet
                        selectedHeight = 68
                    }) {
                        Text("Feet")
                            .font(.poppins(segmentFontSize, weight: .medium))
                            .foregroundColor(selectedUnit == .feet ? .white : .white.opacity(0.8))
                            .frame(maxWidth: .infinity)
                            .frame(height: segmentHeight)
                            .background(
                                Group {
                                    if selectedUnit == .feet {
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
                        selectedUnit = .cm
                        selectedHeight = 173
                    }) {
                        Text("cm")
                            .font(.poppins(segmentFontSize, weight: .medium))
                            .foregroundColor(selectedUnit == .cm ? .white : .white.opacity(0.8))
                            .frame(maxWidth: .infinity)
                            .frame(height: segmentHeight)
                            .background(
                                Group {
                                    if selectedUnit == .cm {
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

                HeightPickerView(
                    selectedHeight: $selectedHeight,
                    heightRange: heightRange,
                    unit: selectedUnit
                )
                .frame(height: isPad ? 150 : 120)
                .padding(.top, 6)

                OnboardingContinueButton(
                    title: "Continue",
                    isEnabled: selectedHeight != nil,
                    animateIn: true,
                    bottomPadding: isPad ? 50 : 40
                ) {
                    guard let h = selectedHeight else { return }
                    
                    let heightInCm: Int
                    switch selectedUnit {
                    case .cm:
                        heightInCm = h
                    case .feet:
                        let cm = Double(h) * 2.54
                        heightInCm = Int((cm).rounded())
                    }
                    
                    onContinue?("\(heightInCm)")
                }
                
                Spacer()
            }
        }
        .navigationBarBackButtonHidden(false)
        .onAppear {
            if isFromSettings {
                let saved = appState.getFromUserDefault(key: UserDefaultsKeys.userHeight)
                if !saved.isEmpty {
                    selectedHeight = Int(saved)
                }
            }
            
            if selectedHeight == nil {
                selectedHeight = selectedUnit == .cm ? 173 : 68
            }
        }
    }
}

struct HeightPickerView: View {
    @Binding var selectedHeight: Int?
    let heightRange: [Int]
    let unit: HeightStatsView.HeightUnit
    
    private var isPad: Bool { UIDevice.current.userInterfaceIdiom == .pad }
    private var itemSpacing: CGFloat { isPad ? 18 : 14 }
    private var itemSize: CGFloat { isPad ? 120 : 100 }
    private var selectedFontSize: CGFloat { isPad ? 52 : 44 }
    private var unselectedFontSize: CGFloat { isPad ? 26 : 22 }
    
    @State private var itemCenters: [Int: CGFloat] = [:]
    @State private var isDragging = false
    
    var body: some View {
        GeometryReader { geometry in
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: itemSpacing) {
                        Color.clear
                            .frame(width: (geometry.size.width - itemSize) / 2)
                        
                        ForEach(heightRange, id: \.self) { h in
                            Button {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                    selectedHeight = h
                                }
                            } label: {
                                ZStack {
                                    if selectedHeight == h {
                                        Circle()
                                            .strokeBorder(Color(hex: "#18EF47").opacity(0.9), lineWidth: 2)
                                            .frame(width: itemSize, height: itemSize)
                                            .shadow(color: Color(hex: "#18EF47").opacity(0.35), radius: 8, x: 0, y: 0)
                                    }
                                    
                                    Text(formattedHeight(h))
                                        .font(.poppins(selectedHeight == h ? selectedFontSize : unselectedFontSize, weight: selectedHeight == h ? .bold : .regular))
                                        .foregroundColor(selectedHeight == h ? Color(hex: "#18EF47") : .white.opacity(0.45))
                                        .frame(width: itemSize, height: itemSize)
                                }
                            }
                            .buttonStyle(.plain)
                            .id(h)
                            .background(
                                GeometryReader { geo in
                                    Color.clear
                                        .preference(
                                            key: ItemCenterPreferenceKey.self,
                                            value: [h: geo.frame(in: .named("picker")).midX]
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
                        .onChanged { _ in isDragging = true }
                        .onEnded { _ in
                            isDragging = false
                            snapToNearestCenter(visibleWidth: geometry.size.width, proxy: proxy)
                        }
                )
                .onAppear {
                    if selectedHeight == nil {
                        selectedHeight = (unit == .cm) ? 173 : 68
                    }
                    if let h = selectedHeight {
                        DispatchQueue.main.async {
                            proxy.scrollTo(h, anchor: .center)
                        }
                    }
                }
                .onChange(of: selectedHeight) { newValue in
                    if let h = newValue {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                            proxy.scrollTo(h, anchor: .center)
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
                selectedHeight = target
                proxy.scrollTo(target, anchor: .center)
            }
        }
    }
    
    private func formattedHeight(_ value: Int) -> String {
        switch unit {
        case .cm:
            return "\(value)"
        case .feet:
            let feet = value / 12
            let inches = value % 12
            return "\(feet)′\(inches)″"
        }
    }
}

#Preview {
    HeightStatsView()
}
