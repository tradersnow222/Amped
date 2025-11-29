import SwiftUI
import PhotosUI

struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm = EditProfileViewModel()
    @ObservedObject private var imageManager = ProfileImageManager.shared
    
    @State private var photoItem: PhotosPickerItem? = nil
    
    // Keyboard handling
    @FocusState private var focusedField: Field?
    private enum Field: Hashable {
        case name, height, weight
    }
    
    var body: some View {
        ZStack {
            LinearGradient.customBlueToDarkGray.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    // Top bar
                    HStack {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "chevron.left")
                                .foregroundColor(.white)
                                .font(.system(size: 18, weight: .semibold))
                        }
                        Spacer()
                        Text("Edit Profile")
                            .font(.poppins(16, weight: .semibold))
                            .foregroundColor(.white.opacity(0.9))
                        Spacer()
                        // Invisible spacer to keep title centered
                        Color.clear.frame(width: 24, height: 24)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    
                    // Avatar
                    ZStack {
                        avatarView
                    }
                    .padding(.top, 8)
                    
                    VStack(alignment: .leading, spacing: 14) {
                        fieldLabel("Name")
                        roundedTextField("Enter your name", text: $vm.fullName, keyboard: .default, focus: .name)
                        
                        fieldLabel("Gender")
                        roundedPicker(selection: Binding(
                            get: { vm.gender ?? .preferNotToSay },
                            set: { vm.gender = $0 }
                        ), options: UserProfile.Gender.allCases.map { ($0, $0.displayName) })
                        
                        fieldLabel("Date of Birth")
                        dateButton()
                        
                        fieldLabel("Height")
                        roundedTextField("Height (cm)", text: $vm.heightText, keyboard: .decimalPad, focus: .height)
                        
                        fieldLabel("Weight")
                        roundedTextField("Weight (kg)", text: $vm.weightText, keyboard: .decimalPad, focus: .weight)
                        
                        // Extended fields (stored in UserDefaults keys)
                        fieldLabel("Stress Level")
                        roundedMenu(selection: $vm.stressLevel, options: ["Very Low","Low","Moderate","High","Very High"])
                        
                        fieldLabel("Anxiety Level")
                        roundedMenu(selection: $vm.anxietyLevel, options: ["Minimal","Mild","Moderate","Severe"])
                        
                        fieldLabel("Typical Diet")
                        roundedMenu(selection: $vm.dietLevel, options: ["Very Healthy","Mostly Healthy","Mixed","Unhealthy"])
                        
                        fieldLabel("Smoke Tobacco")
                        roundedMenu(selection: $vm.smokingStatus, options: ["Never","Former","Occasional","Daily"])
                        
                        fieldLabel("Consume Alcohol")
                        roundedMenu(selection: $vm.alcoholStatus, options: ["Never","Occasional","Several/Week","Daily/Heavy"])
                        
                        fieldLabel("Social Connections")
                        roundedMenu(selection: $vm.socialConnections, options: ["Very Strong","Moderate","Limited","Isolated"])
                        
                        fieldLabel("Blood Pressure")
                        roundedMenu(selection: $vm.bloodPressureCategory, options: ["Below 120/80","120–129/80","130–139/80+","Unknown"])
                        
                        fieldLabel("Reason to Live Longer")
                        roundedMenu(selection: $vm.mainReasonToLive, options: [
                            "Achieve my dreams",
                            "Be there for family",
                            "Experience more life",
                            "Health and vitality",
                            "Other"
                        ])
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    
                    // Save button
                    Button(action: {
                        vm.save()
                        if vm.saveSucceeded {
                            dismiss()
                        }
                    }) {
                        Text(vm.isSaving ? "Saving..." : "Save")
                            .font(.poppins(16, weight: .semibold))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(
                                LinearGradient(colors: [Color(hex: "#18EF47"), Color(hex: "#0E8929")],
                                               startPoint: .leading, endPoint: .trailing)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                            .shadow(color: Color.black.opacity(0.25), radius: 8, x: 0, y: 4)
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 24)
                }
                .contentShape(Rectangle()) // so taps hit outside controls
            }
            // Dismiss keyboard while scrolling (iOS 16+)
            .scrollDismissesKeyboard(.interactively)
            // Dismiss keyboard on outside tap
            .onTapGesture {
                focusedField = nil
            }
        }
        .onAppear {
            vm.load()
        }
        // iOS 16-compatible onChange (single parameter)
        .onChange(of: photoItem) { newValue in
            guard let newValue else { return }
            Task {
                if let data = try? await newValue.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    ProfileImageManager.shared.saveProfileImage(image)
                }
            }
        }
        .alert("Error", isPresented: Binding(get: { vm.errorMessage != nil }, set: { _ in vm.errorMessage = nil })) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(vm.errorMessage ?? "")
        }
    }
    
    // MARK: - Avatar
    
    private var avatarView: some View {
        ZStack(alignment: .bottomTrailing) {
            // Main circle: photo or initials
            Group {
                if let img = imageManager.profileImage {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                } else {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.15))
                        Text(initialsText())
                            .font(.system(size: 40, weight: .semibold))
                            .foregroundColor(.white.opacity(0.9))
                    }
                }
            }
            .frame(width: 120, height: 120)
            .clipShape(Circle())
            .overlay(
                Circle()
                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.25), radius: 8, x: 0, y: 4)
            
            // Camera badge (PhotosPicker trigger)
            PhotosPicker(selection: $photoItem, matching: .images) {
                ZStack {
                    Circle()
                        .fill(Color(hex: "#0E8929").opacity(0.8))
                        .frame(width: 28, height: 28)
                        .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                    Image(systemName: "camera.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .offset(x: 1, y: -6)
            .accessibilityLabel("Change profile photo")
        }
        .frame(width: 120, height: 120)
    }
    
    private func initialsText() -> String {
        let name = vm.fullName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !name.isEmpty {
            let parts = name.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
            let first = parts.first?.prefix(1).uppercased() ?? ""
            let second = parts.dropFirst().first?.prefix(1).uppercased() ?? ""
            return first + second
        }
        return imageManager.getInitials()
    }
    
    // MARK: - Subviews
    
    private func fieldLabel(_ title: String) -> some View {
        Text(title)
            .font(.poppins(13, weight: .medium))
            .foregroundColor(.white.opacity(0.85))
            .padding(.leading, 4)
    }
    
    private func roundedTextField(_ placeholder: String, text: Binding<String>, keyboard: UIKeyboardType = .default, focus: Field) -> some View {
        TextField(placeholder, text: text)
            .keyboardType(keyboard)
            .focused($focusedField, equals: focus)
            .padding(.horizontal, 16)
            .frame(height: 52)
            .background(Color.white.opacity(0.12))
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.white.opacity(0.18), lineWidth: 1))
            .cornerRadius(18)
            .foregroundColor(.white)
    }
    
    private func roundedPicker<T: Hashable>(selection: Binding<T>, options: [(T, String)]) -> some View {
        Picker("", selection: selection) {
            ForEach(options, id: \.0) { value, label in
                Text(label).tag(value)
            }
        }
        .pickerStyle(.menu)
        .tint(.white)
        .padding(.horizontal, 12)
        .frame(height: 52)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.12))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.white.opacity(0.18), lineWidth: 1))
        .cornerRadius(18)
    }
    
    private func roundedMenu(selection: Binding<String>, options: [String]) -> some View {
        Menu {
            ForEach(options, id: \.self) { option in
                Button(option) { selection.wrappedValue = option }
            }
        } label: {
            HStack {
                Text(selection.wrappedValue.isEmpty ? "Select" : selection.wrappedValue)
                    .foregroundColor(.white.opacity(selection.wrappedValue.isEmpty ? 0.4 : 0.95))
                Spacer()
                Image(systemName: "chevron.down").foregroundColor(.white.opacity(0.7))
            }
            .padding(.horizontal, 16)
            .frame(height: 52)
            .background(Color.white.opacity(0.12))
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.white.opacity(0.18), lineWidth: 1))
            .cornerRadius(18)
        }
    }
    
    private func dateButton() -> some View {
        Menu {
            DatePicker("Date of Birth", selection: Binding(
                get: { vm.dateOfBirth ?? Calendar.current.date(from: DateComponents(year: 1990, month: 6, day: 15))! },
                set: { vm.dateOfBirth = $0 }
            ), displayedComponents: .date)
            .datePickerStyle(.graphical)
        } label: {
            HStack {
                Text(formattedDOB(vm.dateOfBirth))
                    .foregroundColor(.white.opacity(vm.dateOfBirth == nil ? 0.4 : 0.95))
                Spacer()
                Image(systemName: "calendar")
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(.horizontal, 16)
            .frame(height: 52)
            .background(Color.white.opacity(0.12))
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.white.opacity(0.18), lineWidth: 1))
            .cornerRadius(18)
        }
    }
    
    private func formattedDOB(_ date: Date?) -> String {
        guard let date else { return "Select Date" }
        let df = DateFormatter()
        df.dateFormat = "dd-MM-yyyy"
        return df.string(from: date)
    }
}

#Preview {
    EditProfileView()
        .environmentObject(AppState())
}
