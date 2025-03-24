import SwiftUI

/// A segmented control for selecting time periods (Day, Month, Year)
struct PeriodSelector: View {
    // MARK: - Properties
    
    @Binding var selectedPeriod: ImpactDataPoint.PeriodType
    
    // MARK: - Body
    
    var body: some View {
        Picker("Time Period", selection: $selectedPeriod) {
            ForEach(ImpactDataPoint.PeriodType.allCases, id: \.self) { period in
                Text(period.displayName)
                    .tag(period)
            }
        }
        .pickerStyle(SegmentedPickerStyle())
        .padding(.horizontal)
    }
}

// MARK: - Preview

struct PeriodSelector_Previews: PreviewProvider {
    static var previews: some View {
        PreviewWrapper()
    }
    
    struct PreviewWrapper: View {
        @StateObject private var state = PreviewState()
        
        var body: some View {
            VStack {
                PeriodSelector(selectedPeriod: $state.selectedPeriod)
                
                Text("Selected period: \(state.selectedPeriod.displayName)")
                    .padding()
            }
            .padding()
            .previewLayout(.sizeThatFits)
        }
    }
    
    private class PreviewState: ObservableObject {
        @Published var selectedPeriod: ImpactDataPoint.PeriodType = .day
    }
} 