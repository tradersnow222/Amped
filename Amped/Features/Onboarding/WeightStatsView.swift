//
//  WeightStatsView.swift
//  Amped
//
//  Created by Yawar Abbas   on 03/11/2025.
//

//
//  WeightStatsView.swift
//  Amped
//
//  Created by Yawar Abbas on 03/11/2025.
//
import SwiftUI

struct WeightStatsView: View {
    @State private var selectedUnit: WeightUnit = .kg
    @State private var selectedWeight: Int? = nil // Changed to optional
    let progress: Double = 0.30
    var onContinue: ((String) -> Void)?
    
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
            LinearGradient.grayGradient
                .ignoresSafeArea()

            VStack(spacing: 24) {
                // Top mascot image
                Image("battery")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .shadow(color: Color.green.opacity(0.35), radius: 18, x: 0, y: 6)
                    .padding(.top, 48)

                Text("Let's set your stats!")
                    .font(.poppins(26, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.top, 4)

                // Progress with percentage below
                VStack(spacing: 6) {
                    GeometryReader { proxy in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.white.opacity(0.15))
                                .frame(height: 10)

                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [Color(hex: "#18EF47"), Color(hex: "#0E8929")],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: max(0, min(proxy.size.width * progress, proxy.size.width)), height: 10)
                        }
                    }
                    .frame(height: 10)
                    .padding(.horizontal, 40)

                    Text("30%")
                        .font(.poppins(12))
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(.bottom, 8)

                VStack(spacing: 8) {
                    Text("Enter your weight to complete")
                        .font(.poppins(16, weight: .medium))
                        .foregroundColor(.white)
                    
                    Text("your charge profile.")
                        .font(.poppins(16, weight: .medium))
                        .foregroundColor(.white)
                }
                .padding(.top, 8)

                // Segmented unit control
                HStack(spacing: 0) {
                    // KG segment
                    Button(action: {
                        selectedUnit = .kg
                        selectedWeight = nil // Reset selection when unit changes
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
                        selectedWeight = nil // Reset selection when unit changes
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
                    .frame(height: 100)
                    .padding(.top, 20)

                Spacer()

                Button(action: {
                    if let weight = selectedWeight {
                        let weightString = "\(weight) \(selectedUnit == .kg ? "KG" : "LB")"
                        onContinue?(weightString)
                    }
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
                .disabled(selectedWeight == nil)
                .opacity(selectedWeight == nil ? 0.5 : 1.0)
                .padding(.bottom, 40)
            }
        }
        .navigationBarBackButtonHidden(false)
    }
}

struct WeightPickerView: View {
    @Binding var selectedWeight: Int?
    let weightRange: [Int]
    
    private let itemSpacing: CGFloat = 10 // Reduced spacing between items
    
    var body: some View {
        GeometryReader { geometry in
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: itemSpacing) {
                        // Leading spacer
                        Color.clear
                            .frame(width: (geometry.size.width / 2) - 100)
                        
                        ForEach(weightRange, id: \.self) { weight in
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    selectedWeight = weight
                                }
                            }) {
                                ZStack {
                                    // Green circle for selected item
                                    if selectedWeight == weight {
                                        Circle()
                                            .strokeBorder(Color(hex: "#02AE54"), lineWidth: 1)
                                            .frame(width: 100, height: 100)
                                    }
                                    
                                    Text("\(weight)")
                                        .font(.poppins(selectedWeight == weight ? 40 : 24, weight: selectedWeight == weight ? .bold : .regular))
                                        .foregroundColor(selectedWeight == weight ? Color(hex: "#18EF47") : .white.opacity(0.4))
                                        .frame(width: 100, height: 100)
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                            .id(weight)
                        }
                        
                        // Trailing spacer
                        Color.clear
                            .frame(width: (geometry.size.width / 2) - 15)
                    }
                }
                .onChange(of: selectedWeight) { newValue in
                    if let weight = newValue {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            proxy.scrollTo(weight, anchor: .center)
                        }
                    }
                }
            }
        }
    }
}
