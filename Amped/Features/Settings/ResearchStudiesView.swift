import SwiftUI
import OSLog

/// Displays all research studies used across the app, grouped by feature area with collapsible sections.
/// Rules applied: Simplicity is KING; MVVM with SwiftUI state only; files under 300 lines; no placeholders.
struct ResearchStudiesView: View {
    @State private var expandedSectionIds: Set<SectionId> = []
    @State private var safariURL: URL?
    @State private var expandedMetricIds: Set<String> = []
    private let logger = Logger(subsystem: "ai.ampedlife.amped", category: "ResearchStudiesView")

    private enum SectionId: Hashable { case activity, cardiovascular, lifestyle }

    private struct StudyRowModel: Identifiable {
        let id: String
        let featureArea: String
        let metric: String
        let title: String
        let subtitle: String?
        let url: URL?
    }

    private var allStudyRows: [StudyRowModel] {
        var rows: [StudyRowModel] = []
        // Existing metric-tied studies
        for metric in HealthMetricType.allCases {
            let studies = StudyReferenceProvider.getStudies(for: metric)
            guard !studies.isEmpty else { continue }
            let area = categoryLabel(for: metric)
            for ref in studies {
                let compositeId = "\(ref.id)_\(metric.rawValue)"
                rows.append(StudyRowModel(id: compositeId, featureArea: area, metric: metric.displayName, title: ref.title, subtitle: compactSubtitle(for: ref), url: ref.primaryURL))
            }
        }
        // Additional groups (e.g., Blood Pressure) not yet represented by a HealthMetricType
        for group in StudyReferenceProvider.additionalSettingsStudyGroups {
            for ref in group.studies {
                let compositeId = "\(ref.id)_extra_\(group.metric.replacingOccurrences(of: " ", with: "_"))"
                rows.append(StudyRowModel(id: compositeId, featureArea: group.featureArea, metric: group.metric, title: ref.title, subtitle: compactSubtitle(for: ref), url: ref.primaryURL))
            }
        }
        return rows
    }

    // Compose a compact subtitle such as: "Lewington (2002) — 1,000,000 participants; 10y; Meta-Analysis"
    private func compactSubtitle(for ref: StudyReference) -> String? {
        var parts: [String] = []
        parts.append(ref.shortCitation)
        if ref.sampleSize > 0 {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            let n = formatter.string(from: NSNumber(value: ref.sampleSize)) ?? "\(ref.sampleSize)"
            parts.append("\(n) participants")
        }
        if let years = ref.followUpYears {
            let yrs = String(format: "%.0f", years)
            parts.append("\(yrs)y")
        }
        parts.append(ref.studyType.rawValue)
        return parts.joined(separator: " — ")
    }

    private var activityStudies: [StudyRowModel] {
        allStudyRows.filter { $0.featureArea == "Activity" }
    }

    private var cardiovascularStudies: [StudyRowModel] {
        allStudyRows.filter { $0.featureArea == "Cardiovascular" }
    }

    private var lifestyleStudies: [StudyRowModel] {
        allStudyRows.filter { $0.featureArea == "Lifestyle" }
    }

    private func categoryLabel(for metric: HealthMetricType) -> String {
        switch metric.functionalGroup {
        case .energySources:
            return "Activity"
        case .recoveryIndicators, .performanceMetrics:
            return "Cardiovascular"
        case .lifestyleFactors, .healthRisks:
            return "Lifestyle"
        }
    }

    var body: some View {
        List {
            Section {
                Text("See the peer‑reviewed research behind our calculations. Tap a study to view it in full.")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }

            DisclosureGroup(isExpanded: Binding(
                get: { expandedSectionIds.contains(.activity) },
                set: { isExpanded in
                    if isExpanded {
                        expandedSectionIds.insert(.activity)
                    } else {
                        expandedSectionIds.remove(.activity)
                    }
                }
            )) {
                studiesList(activityStudies)
            } label: {
                Label("Activity", systemImage: "figure.run")
            }

            DisclosureGroup(isExpanded: Binding(
                get: { expandedSectionIds.contains(.cardiovascular) },
                set: { isExpanded in
                    if isExpanded {
                        expandedSectionIds.insert(.cardiovascular)
                    } else {
                        expandedSectionIds.remove(.cardiovascular)
                    }
                }
            )) {
                studiesList(cardiovascularStudies)
            } label: {
                Label("Cardiovascular", systemImage: "heart")
            }

            DisclosureGroup(isExpanded: Binding(
                get: { expandedSectionIds.contains(.lifestyle) },
                set: { isExpanded in
                    if isExpanded {
                        expandedSectionIds.insert(.lifestyle)
                    } else {
                        expandedSectionIds.remove(.lifestyle)
                    }
                }
            )) {
                studiesList(lifestyleStudies)
            } label: {
                Label("Lifestyle", systemImage: "leaf.fill")
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Research Studies")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $safariURL, onDismiss: { logger.log("SafariView dismissed") }) { url in
            SafariView(url: url)
                .ignoresSafeArea()
        }
        .onChange(of: safariURL) { newValue in
            logger.log("safariURL changed: \(newValue?.absoluteString ?? "nil", privacy: .public)")
        }
    }

    @ViewBuilder
    private func studiesList(_ items: [StudyRowModel]) -> some View {
        // Group by metric and create nested, collapsed-by-default dropdowns
        let groups = Dictionary(grouping: items, by: { $0.metric })
        ForEach(groups.keys.sorted(), id: \.self) { metric in
            let rows = groups[metric] ?? []
            // Compose a stable id per metric within this feature area to track expansion state
            let groupId = (rows.first?.featureArea ?? "") + "_" + metric

            DisclosureGroup(isExpanded: Binding(
                get: { expandedMetricIds.contains(groupId) },
                set: { isExpanded in
                    if isExpanded { expandedMetricIds.insert(groupId) } else { expandedMetricIds.remove(groupId) }
                }
            )) {
                ForEach(rows) { item in
                    Button {
                        if let url = item.url {
                            logger.log("Study tapped id=\(item.id, privacy: .public) url=\(url.absoluteString, privacy: .public)")
                            safariURL = url
                        }
                    } label: {
                        HStack(alignment: .top, spacing: 12) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.title)
                                    .font(.body)
                                    .foregroundColor(.primary)
                                    .fixedSize(horizontal: false, vertical: true)
                                if let subtitle = item.subtitle {
                                    Text(subtitle)
                                        .font(.footnote)
                                        .foregroundColor(.secondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                            Spacer()
                            Image(systemName: "safari")
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            } label: {
                Text(metric)
            }
        }
    }
}

private extension StudyReference {
    // Prefer DOI; fall back to PubMed. External links kept in-app with SFSafariViewController.
    var primaryURL: URL? {
        if let doi, let url = URL(string: "https://doi.org/\(doi)") { return url }
        if let pmid, let url = URL(string: "https://pubmed.ncbi.nlm.nih.gov/\(pmid)/") { return url }
        return nil
    }
}

// Enable data-driven sheet presentation using the URL itself.
// Applied rules: Simplicity is KING; Debugger Mode logging; files under 300 lines.
extension URL: @retroactive Identifiable {
    public var id: String { absoluteString }
}


