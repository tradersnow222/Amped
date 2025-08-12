import SwiftUI
import os

// Rules: Performance optimization monitoring for onboarding flow
struct PerformanceMonitor: ViewModifier {
    let screenName: String
    @State private var appearTime: Date?
    private let logger = Logger(subsystem: "com.amped.performance", category: "Onboarding")
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                appearTime = Date()
                logger.info("🚀 \(screenName) appeared")
            }
            .onDisappear {
                if let appearTime = appearTime {
                    let duration = Date().timeIntervalSince(appearTime)
                    logger.info("⏱️ \(screenName) was visible for \(String(format: "%.2f", duration))s")
                }
            }
    }
}

extension View {
    func trackPerformance(_ screenName: String) -> some View {
        modifier(PerformanceMonitor(screenName: screenName))
    }
}
