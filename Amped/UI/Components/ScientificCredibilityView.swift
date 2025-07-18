import SwiftUI

/// Displays scientific credibility information for health metrics
/// Used to build user trust by showing research backing for questionnaire questions
struct ScientificCredibilityView: View {
    let studyReference: StudyReference
    let style: CredibilityStyle
    
    var body: some View {
        switch style {
        case .inline:
            inlineView
        }
    }
    
    @ViewBuilder
    private var inlineView: some View {
        HStack(spacing: 8) {
            Image(systemName: "graduationcap.fill")
                .foregroundColor(.white.opacity(0.7))
                .font(.system(size: 12))
            
            Text("Backed research: \(studyReference.shortCitation)")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
            
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(.ultraThinMaterial)
                .opacity(0.3)
        )
    }
}

// MARK: - Credibility Style
extension ScientificCredibilityView {
    enum CredibilityStyle {
        case inline
    }
}

// MARK: - Static Factory Methods
extension ScientificCredibilityView {
    /// Creates a credibility view for a specific metric type if research data is available
    /// Returns nil if no study reference is available for the metric
    static func forMetric(_ metricType: HealthMetricType, style: CredibilityStyle) -> ScientificCredibilityView? {
        guard let studyReference = StudyReferenceProvider.getStudyReference(for: metricType) else {
            return nil
        }
        
        return ScientificCredibilityView(
            studyReference: studyReference,
            style: style
        )
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        Color.black
        
        VStack(spacing: 20) {
            if let credibilityView = ScientificCredibilityView.forMetric(.steps, style: .inline) {
                credibilityView
            }
            
            if let credibilityView = ScientificCredibilityView.forMetric(.sleepHours, style: .inline) {
                credibilityView
            }
        }
        .padding()
    }
} 