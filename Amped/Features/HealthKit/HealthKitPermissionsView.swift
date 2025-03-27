import SwiftUI
import HealthKit
import OSLog
import UIKit

/// View for requesting HealthKit permissions following Apple Human Interface Guidelines
struct HealthKitPermissionsView: View {
    // MARK: - Properties
    
    @StateObject private var viewModel = HealthKitPermissionsViewModel(healthKitManager: HealthKitManager())
    
    /// Callbacks for navigation
    var onContinue: (() -> Void)?
    
    /// Logger for tracking user interactions
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.amped.Amped", category: "HealthKitPermissionsView")
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerSection
                .padding(.top, 40)
                .padding(.bottom, 20)
            
            Spacer(minLength: 10)
            
            // Health metrics list with permissions
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Highlight critical metrics at the top
                    if !viewModel.allPermissionsGranted {
                        criticalMetricsSection
                    }
                    
                    // All metrics
                    ForEach(viewModel.healthMetrics) { metric in
                        healthDataRow(
                            icon: metric.icon,
                            title: metric.title,
                            description: metric.description,
                            isGranted: metric.isGranted,
                            isCritical: metric.isCritical
                        )
                    }
                }
                .padding(.horizontal, 30)
            }
            .scrollIndicators(.hidden)
            
            Spacer(minLength: 20)
            
            // Action buttons
            actionButtonsSection
                .padding(.bottom, 20)
            
            // Progress indicator
            ProgressIndicator(currentStep: 8, totalSteps: 10)
                .padding(.bottom, 40)
        }
        .withDeepBackground()
        .alert("Health Access Error", isPresented: $viewModel.showError) {
            Button("Open Settings", role: .none) {
                openSettings()
            }
            
            Button("Try Again", role: .none) {
                viewModel.clearErrorState()
                requestHealthKitPermissions()
            }
            
            Button("OK", role: .cancel) {
                viewModel.clearErrorState()
            }
        } message: {
            Text(viewModel.errorMessage)
        }
        .onAppear {
            // Clear any persistent error state when the view appears
            viewModel.clearErrorState()
            
            // Check if permissions were already granted when view appears
            checkExistingPermissions()
        }
        // Critical addition: Monitor for iOS health permission dialog return
        // This uses NotificationCenter to detect when the app becomes active again
        // which happens after returning from the system permission dialog
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            logger.info("App became active again - likely returned from Health permission dialog")
            Task {
                // Skip waiting and immediately check for permissions
                // The system should have already updated the authorization status
                logger.info("Checking permissions status after app becomes active")
                await viewModel.checkPermissionsStatus(forceRefresh: true)
                
                // If permissions are granted, proceed to the next screen
                if viewModel.allPermissionsGranted || viewModel.criticalPermissionsGranted {
                    logger.info("Permissions detected after returning from system dialog, continuing")
                    onContinue?()
                } else {
                    logger.info("Permissions not detected by status check, trying direct data access validation")
                    
                    // Create a new HealthKit manager with a fresh store to avoid any caching issues
                    let healthKitManager = HealthKitManager(healthStore: HKHealthStore())
                    
                    // Important: Instead of checking permissions, try to actually access health data
                    // This is more reliable because it tests what we actually need - data access
                    let canAccessHealthData = await healthKitManager.validatePermissionsByAccessingData()
                    
                    if canAccessHealthData {
                        logger.info("Successfully validated permissions by accessing health data")
                        await viewModel.checkPermissionsStatus(forceRefresh: true)
                        logger.info("Proceeding to next screen after successful data access validation")
                        onContinue?()
                    } else {
                        // Last resort: Try with a direct authorization request
                        // This might re-prompt for permissions if needed
                        logger.info("Attempting direct authorization request as final check")
                        let hasPermissions = await healthKitManager.requestAuthorization(for: HealthKitManager.criticalMetricTypes)
                        
                        // If permissions are now detected, refresh the viewModel and proceed
                        if hasPermissions {
                            logger.info("Permissions granted after direct authorization request")
                            await viewModel.checkPermissionsStatus(forceRefresh: true)
                            onContinue?()
                        } else {
                            logger.warning("Permissions still not detected after all validation attempts")
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - View Components
    
    /// Header section with title and description
    private var headerSection: some View {
        VStack(spacing: 12) {
            Text("Health Access")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .accessibilityAddTraits(.isHeader)
            
            Text("Allow Amped to access health data to calculate your life battery")
                .font(.headline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .accessibilityHint("This data helps personalize your experience")
        }
    }
    
    /// Action buttons section with primary and secondary buttons
    private var actionButtonsSection: some View {
        VStack(spacing: 16) {
            // Primary action button - more prominent since permissions are mandatory
            Button(action: requestHealthKitPermissions) {
                HStack {
                    if !viewModel.isRequestingPermissions {
                        Image(systemName: "heart.fill")
                            .font(.body)
                            .foregroundColor(.white)
                    }
                    
                    Text(viewModel.isRequestingPermissions ? "Requesting..." : "Continue")
                        .fontWeight(.bold)
                    
                    if viewModel.isRequestingPermissions {
                        ProgressView()
                            .controlSize(.small)
                            .tint(.white)
                            .padding(.leading, 4)
                    }
                }
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16) // Taller button for emphasis
                .background(viewModel.isRequestingPermissions ? Color.gray : Color.ampedGreen)
                .foregroundColor(.white)
                .cornerRadius(14)
            }
            .disabled(viewModel.isRequestingPermissions || viewModel.allPermissionsGranted)
            .padding(.horizontal, 40)
            .hapticFeedback()
            .accessibilityHint("Continue and request access to health data")
            
            // Explanatory text to emphasize that permissions are mandatory
            if !viewModel.allPermissionsGranted {
                Text("Health data access is required to calculate your life battery")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
        }
    }
    
    /// Critical metrics section highlighting the most important permissions
    private var criticalMetricsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Essential Health Data")
                .font(.headline)
                .foregroundColor(.primary)
                .padding(.bottom, 4)
            
            Text("These metrics are required for basic app functionality:")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.bottom, 8)
        }
    }
    
    /// Health data row with icon, text, and status indicator
    private func healthDataRow(icon: String, title: String, description: String, isGranted: Bool, isCritical: Bool = false) -> some View {
        HStack(spacing: 20) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundColor(isGranted ? .ampedGreen : (isCritical ? .ampedYellow : .ampedSilver))
                .frame(width: 36, height: 36)
                .accessibility(hidden: true)
            
            // Text content
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    if isCritical {
                        Text("Required")
                            .font(.caption)
                            .foregroundColor(.ampedYellow)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.ampedYellow.opacity(0.2))
                            .cornerRadius(4)
                    }
                }
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            .accessibilityElement(children: .combine)
            
            Spacer()
            
            // Status indicator
            if isGranted {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.ampedGreen)
                    .accessibility(label: Text("Permission granted"))
            } else if isCritical {
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundColor(.ampedYellow)
                    .accessibility(label: Text("Required permission needed"))
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title) \(isGranted ? "permission granted" : "permission needed")\(isCritical ? ", required" : "")")
        .accessibilityHint(description)
    }
    
    // MARK: - Helper Methods
    
    /// Check if permissions have already been granted when the view appears
    private func checkExistingPermissions() {
        Task {
            logger.info("Checking existing HealthKit permissions")
            
            // Force refresh to get an accurate reading of current permissions
            await viewModel.checkPermissionsStatus(forceRefresh: true)
            
            // Check if permissions are granted using the published properties
            let canContinue = viewModel.allPermissionsGranted || viewModel.criticalPermissionsGranted
            
            if canContinue {
                logger.info("Sufficient permissions already granted by status check, continuing")
                
                // Clear any error state just to be safe
                viewModel.clearErrorState()
                
                // Important: Call onContinue on the main thread
                DispatchQueue.main.async {
                    self.onContinue?()
                }
            } else {
                logger.info("Permissions not detected by status check, trying data access validation")
                
                // Create a fresh HealthKit manager to avoid any caching issues
                let healthKitManager = HealthKitManager(healthStore: HKHealthStore())
                
                // Important: Try to validate permissions by actually accessing health data
                // This is the most reliable test of whether permissions are truly granted
                let canAccessHealthData = await healthKitManager.validatePermissionsByAccessingData()
                
                if canAccessHealthData {
                    logger.info("Successfully validated permissions by accessing health data")
                    await viewModel.checkPermissionsStatus(forceRefresh: true)
                    logger.info("Proceeding to next screen after successful data access validation")
                    
                    DispatchQueue.main.async {
                        self.onContinue?()
                    }
                } else {
                    logger.info("Permissions not yet granted, staying on permissions screen")
                }
            }
        }
    }
    
    /// Request HealthKit permissions directly from the view
    private func requestHealthKitPermissions() {
        // Clear any error state before proceeding
        viewModel.clearErrorState()
        
        logger.info("User initiating HealthKit permission request")
        
        Task {
            let granted = await viewModel.requestHealthKitPermissions()
            
            // Force a permission check again after the request
            logger.info("Checking permission status after explicit request")
            await viewModel.checkPermissionsStatus(forceRefresh: true)
            
            // Extra check to make sure we're considering the latest permission state
            let hasPermissions = viewModel.allPermissionsGranted || viewModel.criticalPermissionsGranted
            
            if granted || hasPermissions {
                logger.info("HealthKit permissions granted by status check, continuing to next screen")
                
                // Clear any error state just to be safe
                viewModel.clearErrorState()
                
                // Important: Call onContinue on the main thread
                DispatchQueue.main.async {
                    self.onContinue?()
                }
            } else {
                logger.warning("HealthKit permissions not detected by status check, trying data access validation")
                
                // Create a fresh HealthKit manager to avoid any caching issues
                let healthKitManager = HealthKitManager(healthStore: HKHealthStore())
                
                // Important: Try to validate permissions by actually accessing health data
                let canAccessHealthData = await healthKitManager.validatePermissionsByAccessingData()
                
                if canAccessHealthData {
                    logger.info("Successfully validated permissions by accessing health data")
                    await viewModel.checkPermissionsStatus(forceRefresh: true)
                    logger.info("Proceeding to next screen after successful data access validation")
                    
                    DispatchQueue.main.async {
                        self.onContinue?()
                    }
                } else {
                    logger.warning("Permissions not granted even after data access validation attempt")
                }
            }
        }
    }
    
    /// Open the iOS Settings app to allow the user to change permissions
    private func openSettings() {
        logger.info("Opening iOS Settings app for user to manage health permissions")
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Preview

#if DEBUG
struct HealthKitPermissionsView_Previews: PreviewProvider {
    static var previews: some View {
        HealthKitPermissionsView(onContinue: {
            print("Continue tapped in preview")
        })
    }
}
#endif 