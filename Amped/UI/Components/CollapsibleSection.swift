import SwiftUI

/// A collapsible section component with smooth animations
struct CollapsibleSection<Content: View>: View {
    let title: String
    let iconName: String
    @Binding var isExpanded: Bool
    let content: Content
    
    @EnvironmentObject var themeManager: BatteryThemeManager
    
    init(title: String, iconName: String, isExpanded: Binding<Bool>, @ViewBuilder content: () -> Content) {
        self.title = title
        self.iconName = iconName
        self._isExpanded = isExpanded
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Image(systemName: iconName)
                        .foregroundColor(themeManager.accentColor)
                        .font(.system(size: 18))
                    
                    Text(title)
                        .style(.bodyMedium)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                        .font(.system(size: 14, weight: .medium))
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.cardBackground)
                )
            }
            .buttonStyle(PlainButtonStyle())
            
            if isExpanded {
                content
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.cardBackground.opacity(0.6))
                    )
                    .padding(.top, 8)
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .top)),
                        removal: .opacity
                    ))
            }
        }
    }
} 