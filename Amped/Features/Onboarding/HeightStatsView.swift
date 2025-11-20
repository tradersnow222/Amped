//
//  HeightStatsView.swift
//  Amped
//
//  Created by Yawar Abbas   on 03/11/2025.
//
import SwiftUI

struct HeightStatsView: View {
    @State private var selectedUnit: HeightUnit = .cm
    // Default to 173 cm as requested
    @State private var selectedHeight: Int? = 173
    let progress: Double = 4
    var onContinue: ((String) -> Void)?
    var onBack: (() -> Void)?
    
    enum HeightUnit: Int {
        case feet = 0   // We show inches when this is selected (e.g., 68 = 5'8")
        case cm = 1
    }
    
    // Ranges for height based on selected unit
    private var heightRange: [Int] {
        switch selectedUnit {
        case .cm:
            return Array(120...220) // cm range
        case .feet:
            return Array(48...84)   // inches range (4'0" to 7'0")
        }
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
                    
                    Text("23%")
                        .font(.poppins(12))
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(.bottom, 30)

                Text("How tall are you?")
                    .font(.poppins(18, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.top, 8)

                // Segmented unit control with matching background and gradient on selected segment
                HStack(spacing: 0) {
                    // Feet segment
                    Button(action: {
                        selectedUnit = .feet
                        // Default for inches (5'8" = 68 in)
                        selectedHeight = 68
                    }) {
                        Text("Feet")
                            .font(.poppins(14, weight: .medium))
                            .foregroundColor(selectedUnit == .feet ? .white : .white.opacity(0.8))
                            .frame(maxWidth: .infinity)
                            .frame(height: 45)
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

                    // cm segment
                    Button(action: {
                        selectedUnit = .cm
                        // Default as requested
                        selectedHeight = 173
                    }) {
                        Text("cm")
                            .font(.poppins(14, weight: .medium))
                            .foregroundColor(selectedUnit == .cm ? .white : .white.opacity(0.8))
                            .frame(maxWidth: .infinity)
                            .frame(height: 45)
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

                // Height horizontal picker (matches weight style)
                HeightPickerView(
                    selectedHeight: $selectedHeight,
                    heightRange: heightRange,
                    unit: selectedUnit
                )
                .frame(height: 120)
                .padding(.top, 6)

                Button(action: {
                    guard let h = selectedHeight else { return }
                    
                    // Normalize to CM for saving/calculation
                    let heightInCm: Int
                    switch selectedUnit {
                    case .cm:
                        heightInCm = h
                    case .feet:
                        // Here "h" is inches; convert inches → cm
                        let cm = Double(h) * 2.54
                        heightInCm = Int((cm).rounded())
                    }
                    
                    // Always pass cm (as String) to the continuation
                    onContinue?("\(heightInCm)")
                }) {
                    Text("Continue")
                        .font(.system(size: 17, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(
                            LinearGradient(
                                colors: [Color(hex: "#18EF47"), Color(hex: "#0E8929")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(30)
                        .foregroundColor(.white)
                        .padding(.horizontal, 40)
                        .shadow(color: Color.black.opacity(0.25), radius: 5, x: 0, y: 3)
                }
                .disabled(selectedHeight == nil)
                .opacity(selectedHeight == nil ? 0.5 : 1.0)
                .padding(.top, 20)
                .padding(.bottom, 40)
                
                Spacer()
            }
        }
        .navigationBarBackButtonHidden(false)
    }
}

struct HeightPickerView: View {
    @Binding var selectedHeight: Int?
    let heightRange: [Int]
    let unit: HeightStatsView.HeightUnit
    
    private let itemSpacing: CGFloat = 14
    private let itemSize: CGFloat = 100
    
    var body: some View {
        GeometryReader { geometry in
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: itemSpacing) {
                        // Leading spacer to center the first item
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
                                        .font(.poppins(selectedHeight == h ? 44 : 22, weight: selectedHeight == h ? .bold : .regular))
                                        .foregroundColor(selectedHeight == h ? Color(hex: "#18EF47") : .white.opacity(0.45))
                                        .frame(width: itemSize, height: itemSize)
                                }
                            }
                            .buttonStyle(.plain)
                            .id(h)
                        }
                        
                        // Trailing spacer to center the last item
                        Color.clear
                            .frame(width: (geometry.size.width - itemSize) / 2)
                    }
                }
                .onAppear {
                    // Ensure default selection is visible/centered
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
    
    private func formattedHeight(_ value: Int) -> String {
        switch unit {
        case .cm:
            return "\(value)"
        case .feet:
            // value is inches; convert to ft'in"
            let feet = value / 12
            let inches = value % 12
            return "\(feet)′\(inches)″"
        }
    }
}

#Preview {
    HeightStatsView()
}
