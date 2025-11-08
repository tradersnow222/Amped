import SwiftUI
import Charts

/// Contains the various sections of the MetricDetailView to reduce file size
struct MetricDetailSections {
    
    // MARK: - Impact Section
    
    struct ImpactSection: View {
        let metric: HealthMetric
        
        var body: some View {
            VStack(alignment: .leading, spacing: 16) {
                Text("Impact Details")
                    .style(.headline)
                    .padding(.horizontal)
                
                if let impact = metric.impactDetails {
                    VStack(alignment: .leading, spacing: 8) {
                        let comparisonDescription = impact.lifespanImpactMinutes > 0 ? "better than the baseline" : (impact.lifespanImpactMinutes < 0 ? "worse than the baseline" : "at the baseline")
                        Text("Your \(metric.type.displayName.lowercased()) is \(comparisonDescription).")
                            .style(.body)
                        
                        Text("This impacts your lifespan by approximately \(impact.formattedImpact(for: .day)).")
                            .style(.body)
                        
                        if impact.lifespanImpactMinutes > 0 {
                            Text("This is a positive impact on your health! 🎉")
                                .style(.bodyMedium, color: .ampedGreen)
                        } else if impact.lifespanImpactMinutes < 0 {
                            Text("This is currently reducing your projected lifespan.")
                                .style(.bodyMedium, color: .ampedRed)
                        } else {
                            Text("This is in line with typical health outcomes.")
                                .style(.bodyMedium)
                        }
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.cardBackground))
                    .padding(.horizontal)
                } else {
                    Text("Impact data unavailable")
                        .style(.bodySecondary)
                        .padding(.horizontal)
                }
            }
        }
    }
    
    // MARK: - Chart Section
    
    struct ChartSection: View {
        let metric: HealthMetric
        let historyData: [HistoryDataPoint]
        let getChartYRange: (HealthMetric) -> ClosedRange<Double>
        
        var body: some View {
            VStack(alignment: .leading, spacing: 16) {
                Text("History")
                    .style(.headline)
                    .padding(.horizontal)
                
                if !historyData.isEmpty {
                    metricHistoryChart
                        .frame(height: 200)
                        .padding(.horizontal)
                } else {
                    ProgressView()
                        .frame(height: 200)
                        .frame(maxWidth: .infinity)
                }
            }
        }
        
        private var metricHistoryChart: some View {
            Chart {
                ForEach(historyData) { dataPoint in
                    LineMark(
                        x: .value("Date", dataPoint.date),
                        y: .value(metric.type.displayName, dataPoint.value)
                    )
                    .foregroundStyle(metric.impactDetails?.lifespanImpactMinutes ?? 0 >= 0 ? Color.green : Color.red)
                    
                    AreaMark(
                        x: .value("Date", dataPoint.date),
                        y: .value(metric.type.displayName, dataPoint.value)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                (metric.impactDetails?.lifespanImpactMinutes ?? 0 >= 0 ? Color.green : Color.red).opacity(0.3),
                                (metric.impactDetails?.lifespanImpactMinutes ?? 0 >= 0 ? Color.green : Color.red).opacity(0.0)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }
                
                if let targetValue = metric.type.targetValue {
                    RuleMark(y: .value("Target", targetValue))
                        .foregroundStyle(Color.gray.opacity(0.5))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                        .annotation(position: .leading) {
                            Text("Target")
                                .font(.caption)
                                .foregroundStyle(Color.secondary)
                        }
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: 7)) { _ in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel()
                }
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel("\(value.index)")
                }
            }
            .chartYScale(domain: getChartYRange(metric))
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Chart showing \(metric.type.displayName) history over time")
        }
    }
    
    // MARK: - Research Section
    
    struct ResearchSection: View {
        let metric: HealthMetric
        
        var body: some View {
            VStack(alignment: .leading, spacing: 16) {
                Text("Research Reference")
                    .style(.headline)
                    .padding(.horizontal)
                
                if let firstStudy = metric.impactDetails?.studyReferences.first {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Research Reference")
                            .style(.subheadlineBold)
                        
                        Text(firstStudy.citation)
                            .style(.caption)
                            .padding(.top, 4)
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.cardBackground))
                    .padding(.horizontal)
                } else {
                    Text("No research reference available")
                        .style(.bodySecondary)
                        .padding(.horizontal)
                }
            }
        }
    }
    
    // MARK: - Recommendations Section
    
    struct RecommendationsSection: View {
        let recommendations: [MetricRecommendation]
        let logAction: (MetricRecommendation) -> Void
        @EnvironmentObject var themeManager: BatteryThemeManager
        
        var body: some View {
            VStack(alignment: .leading, spacing: 16) {
                Text("Recommendations")
                    .style(.headline)
                    .padding(.horizontal)
                
                ForEach(recommendations) { recommendation in
                    recommendationCard(recommendation)
                }
            }
        }
        
        private func recommendationCard(_ recommendation: MetricRecommendation) -> some View {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: recommendation.iconName)
                        .foregroundColor(themeManager.accentColor)
                    
                    Text(recommendation.title)
                        .style(.headlineBold)
                }
                
                Text(recommendation.description)
                    .style(.body)
                
                if !recommendation.actionText.isEmpty {
                    Button {
                        // In a real app, this would perform the action
                        // For MVP, just log it
                        logAction(recommendation)
                    } label: {
                        Text(recommendation.actionText)
                            .style(.buttonLabel, color: .white)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                            .background(RoundedRectangle(cornerRadius: 8).fill(themeManager.accentColor))
                    }
                    .padding(.top, 4)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.cardBackground)
            )
            .padding(.horizontal)
        }
    }
    
    // MARK: - Power Level Indicator
    
    struct PowerLevelIndicator: View {
        let powerLevel: Int
        let powerColor: Color
        
        var body: some View {
            VStack(alignment: .trailing, spacing: 4) {
                Text("Power Level")
                    .style(.caption)
                
                // Battery power level
                HStack(spacing: 2) {
                    ForEach(0..<5) { i in
                        PowerLevelBar(
                            isActive: i < powerLevel,
                            activeColor: powerColor,
                            height: 8 + CGFloat(i) * 2
                        )
                    }
                }
                .padding(.top, 4)
            }
        }
    }
    
    struct PowerLevelBar: View {
        let isActive: Bool
        let activeColor: Color
        let height: CGFloat
        
        var body: some View {
            RoundedRectangle(cornerRadius: 1)
                .fill(isActive ? activeColor : Color.gray.opacity(0.3))
                .frame(width: 3, height: height)
        }
    }
    
    // MARK: - Header Section
    
    struct HeaderSection: View {
        let metric: HealthMetric
        let powerLevel: Int
        let powerColor: Color
        @EnvironmentObject var themeManager: BatteryThemeManager
        
        var body: some View {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: metric.type.symbolName)
                                .foregroundColor(metric.type.color)
                                .textStyle(.title)
                            
                            Text(metric.type.displayName)
                                .style(.title)
                        }
                        
                        Text(metric.formattedValue)
                            .style(.metricValue, color: themeManager.getThemeColor(for: .metricValue))
                    }
                    
                    Spacer()
                    
                    // Power level indicator
                    PowerLevelIndicator(powerLevel: powerLevel, powerColor: powerColor)
                }
                .padding(.horizontal)
            }
        }
    }
} 
