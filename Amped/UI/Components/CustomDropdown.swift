import SwiftUI

/// Dropdown option with separate value and display text
struct DropdownOption<T: Hashable>: Hashable {
    let value: T
    let displayText: String
    
    init(value: T, displayText: String) {
        self.value = value
        self.displayText = displayText
    }
}

/// A reusable custom dropdown component with full-width white background options
struct CustomDropdown<T: Hashable>: View {
    // MARK: - Properties
    
    let title: String
    let placeholder: String
    let options: [DropdownOption<T>]
    @Binding var selection: T?
    
    @State private var isExpanded = false
    
    // MARK: - Initializers
    
    /// Main initializer - works with DropdownOption array
    init(
        title: String = "",
        placeholder: String,
        options: [DropdownOption<T>],
        selection: Binding<T?>
    ) {
        self.title = title
        self.placeholder = placeholder
        self.options = options
        self._selection = selection
    }
    
    /// Convenience initializer with value/display closure
    init(
        title: String = "",
        placeholder: String,
        options: [T],
        selection: Binding<T?>,
        displayText: @escaping (T) -> String
    ) {
        self.title = title
        self.placeholder = placeholder
        self.options = options.map { DropdownOption(value: $0, displayText: displayText($0)) }
        self._selection = selection
    }
    
    /// Convenience initializer for CaseIterable enums
    init(
        title: String = "",
        placeholder: String,
        selection: Binding<T?>,
        displayText: @escaping (T) -> String
    ) where T: CaseIterable {
        self.init(
            title: title,
            placeholder: placeholder,
            options: Array(T.allCases),
            selection: selection,
            displayText: displayText
        )
    }
    
    /// Convenience initializer for String arrays
    init(
        title: String = "",
        placeholder: String,
        options: [String],
        selection: Binding<String?>
    ) where T == String {
        self.init(
            title: title,
            placeholder: placeholder,
            options: options.map { DropdownOption(value: $0, displayText: $0) },
            selection: selection
        )
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 8) {
            // Title (optional)
            if !title.isEmpty {
                HStack {
                    Text(title)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.white)
                    Spacer()
                }
                .padding(.horizontal, 24)
            }
            
            ZStack(alignment: .topLeading) {
                // Main dropdown button
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isExpanded.toggle()
                    }
                }) {
                    HStack {
                        Text(selectedText)
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(selectedText == placeholder ? Color(red: 0.15, green: 0.15, blue: 0.15, opacity: 0.4) : .black)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.down")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.black)
                            .rotationEffect(.degrees(isExpanded ? 180 : 0))
                            .animation(.easeInOut(duration: 0.2), value: isExpanded)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.white)
                            .shadow(color: .black.opacity(0.05), radius: 1, x: 0, y: 1)
                    )
                }
                
                // Dropdown options anchored below the button
                if isExpanded {
                    VStack(spacing: 0) {
                        ForEach(options, id: \.self) { option in
                            Button(action: {
                                selection = option.value
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    isExpanded = false
                                }
                            }) {
                                HStack {
                                    Text(option.displayText)
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.black)
                                    
                                    Spacer()
                                    
                                    if selection == option.value {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(.accentColor)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 14)
                                .background(Color.white)
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            if option != options.last {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(height: 1)
                            }
                        }
                    }
                    .background(Color.white)
                    .cornerRadius(6)
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                    .offset(y: 48) // Position just below the button
                    .zIndex(1)
                }
            }
            .padding(.horizontal, 24)
        }
    }
    
    // MARK: - Helper Properties
    
    private var selectedText: String {
        if let selection = selection,
           let selectedOption = options.first(where: { $0.value == selection }) {
            return selectedOption.displayText
        } else {
            return placeholder
        }
    }
}

// MARK: - Convenience Extensions

// Note: Specific extensions for app types (like UserProfile.Gender) 
// should be added in the files where those types are used to avoid import dependencies

// MARK: - Preview

struct CustomDropdown_Previews: PreviewProvider {
    @State static var selectedCountry: String? = nil
    @State static var selectedNumber: Int? = nil
    
    enum SampleEnum: String, CaseIterable {
        case option1 = "Option 1"
        case option2 = "Option 2" 
        case option3 = "Option 3"
    }
    @State static var selectedEnum: SampleEnum? = nil
    
    static var previews: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 32) {
                // Enum dropdown (CaseIterable)
                CustomDropdown(
                    title: "Select option",
                    placeholder: "Choose option",
                    selection: $selectedEnum,
                    displayText: { $0.rawValue }
                )
                
                // String array dropdown
                CustomDropdown(
                    title: "Select your country",
                    placeholder: "Choose country",
                    options: ["United States", "Canada", "United Kingdom", "Australia"],
                    selection: $selectedCountry
                )
                
                // Custom type dropdown with value/display separation
                CustomDropdown(
                    title: "Select number",
                    placeholder: "Pick a number",
                    options: [
                        DropdownOption(value: 1, displayText: "One (1)"),
                        DropdownOption(value: 2, displayText: "Two (2)"),
                        DropdownOption(value: 5, displayText: "Five (5)"),
                        DropdownOption(value: 10, displayText: "Ten (10)")
                    ],
                    selection: $selectedNumber
                )
                
                Spacer()
            }
            .padding(.top, 100)
        }
        .preferredColorScheme(.dark)
    }
}
