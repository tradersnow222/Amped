//
//  HeightStatsView.swift
//  Amped
//
//  Created by Yawar Abbas   on 03/11/2025.
//
import SwiftUI

struct HeightStatsView: View {
    @State private var selectedUnit: HeightUnit = .feet
    @State private var heightValue: String = ""
    let progress: Double = 0.25
    var onContinue: ((String) -> Void)?
    
    private var isInputValid: Bool {
        !heightValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func dismissKeyboard() {
    #if canImport(UIKit)
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    #endif
    }
    
    enum HeightUnit: Int {
        case feet = 0
        case cm = 1
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

                    Text("23%")
                        .font(.poppins(12))
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(.bottom, 8)

                Text("How tall are you?")
                    .font(.poppins(18, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.top, 8)

                // Segmented unit control with matching background and gradient on selected segment
                HStack(spacing: 0) {
                    // Feet segment
                    Button(action: {
                        selectedUnit = .feet
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
//                    .buttonStyle(.plain)
                    .frame(maxWidth: .infinity)

                    // cm segment
                    Button(action: {
                        selectedUnit = .cm
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
//                    .buttonStyle(.plain)
                    .frame(maxWidth: .infinity)
                }
                .background(
                    // Match TextField background style
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Color.white.opacity(0.08))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .padding(.horizontal, 32)
                .onChange(of: selectedUnit) { new in
                    // reset input when unit changes
                    heightValue = ""
                }
                .padding(.top, 4)

                // Height input styled capsule with green outline
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white.opacity(0.08))
                        .frame(height: 54)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color(hex: "#18EF47").opacity(0.8), lineWidth: 1)
                        )
                        .padding(.horizontal, 32)
                    
                    if heightValue.isEmpty {
                        Text(selectedUnit == .feet ? "Enter height in inches" : "Enter height in cm")
                            .foregroundColor(Color.white.opacity(0.2))
                    }

                    TextField("", text: $heightValue)
                        .keyboardType(.decimalPad)
                        .submitLabel(.done)
                        .onChange(of: heightValue) { new in
                            // keep only digits
                            let filtered = new.onlyDecimal()
                            if filtered != new { heightValue = filtered }
                        }
                        .font(.poppins(16, weight: .medium))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .frame(height: 54)
                        .padding(.horizontal, 48)
                }


                Button(action: {
                    onContinue?(heightValue)
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
                .disabled(!isInputValid)
                .opacity(isInputValid ? 1.0 : 0.5)
                .padding(.top, 20)
                .padding(.bottom, 40)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            dismissKeyboard()
        }
        .navigationBarBackButtonHidden(false)
    }
}

private extension String {
    func onlyDigits() -> String {
        self.filter { $0.isNumber }
    }
    
    func onlyDecimal() -> String {
        // Allow digits and a single decimal point
        var result = ""
        var hasDecimalPoint = false
        
        for char in self {
            if char.isNumber {
                result.append(char)
            } else if char == "." && !hasDecimalPoint {
                result.append(char)
                hasDecimalPoint = true
            }
        }
        return result
    }
}

private extension View {
    @ViewBuilder
    func tinctureFix() -> some View {
        self
            .tint(.clear)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "#18EF47"), Color(hex: "#0E8929")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

