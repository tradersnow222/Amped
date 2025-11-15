import SwiftUI

struct AgeSelectionView: View {
    @State var progress: CGFloat = 3
    var onContinue: ((Date) -> Void)?
    var onBack:(() -> Void)?
    @State private var dateOfBirth: Date = Calendar.current.date(byAdding: .year, value: -18, to: Date()) ?? Date()
    
    private let minDate: Date = {
        var components = DateComponents()
        components.year = 1900
        components.month = 1
        components.day = 1
        return Calendar.current.date(from: components) ?? Date()
    }()
    
    private let maxDate: Date = Date()
    
    var body: some View {
        ZStack {
            LinearGradient.grayGradient
                .ignoresSafeArea()

            VStack(spacing: 20) {
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
                
                Image("battery")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .shadow(color: Color.green.opacity(0.5), radius: 15, x: 0, y: 5)
                    .padding(.top, 20)

                Text("Let's set your stats!")
                    .font(.poppins(26, weight: .bold))
                    .foregroundColor(.white)

                VStack(spacing: 4) {
                    ProgressView(value: progress, total: 13)
                        .progressViewStyle(ThickProgressViewStyle(height: 12))
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 40)

                    Text("15%")
                        .font(.poppins(12))
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(.bottom, 20)

                Text("How many years have you powered through life?")
                    .font(.poppins(18, weight: .medium))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                
                HStack {
                    Text("Date")
                        .font(.poppins(16, weight: .bold))
                        .foregroundColor(Color(hex: "#18EF47"))
                    
                    Spacer()
                    
                    Text("Month")
                        .font(.poppins(16, weight: .bold))
                        .foregroundColor(Color(hex: "#18EF47"))
                    
                    Spacer()
                    
                    Text("Year")
                        .font(.poppins(16, weight: .bold))
                        .foregroundColor(Color(hex: "#18EF47"))
                }
                .padding(.horizontal, 80)
                .padding(.top, 10)
                
                // DatePicker wheel container
                DatePicker(
                    "",
                    selection: $dateOfBirth,
                    in: minDate...maxDate,
                    displayedComponents: [.date]
                )
                .datePickerStyle(.wheel)
                .tint(Color(hex: "#18EF47"))
                .foregroundStyle(.white)
                .environment(\.colorScheme, .dark)
                .frame(maxWidth: .infinity)
                .clipped()
                .labelsHidden()
                .padding(.bottom, 10)

                
                Button(action: {
                    onContinue?(dateOfBirth)
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
                .padding(.top, 10)

                Spacer()

            }
        }
        .navigationBarBackButtonHidden(false)
    }
}

#Preview {
    AgeSelectionView(progress: 2) { date in
        print("Selected DOB: \(date)")
    }
}
