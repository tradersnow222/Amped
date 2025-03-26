import SwiftUI
import HealthKit
import OSLog

/// View for requesting HealthKit permissions following Apple Human Interface Guidelines
struct HealthKitPermissionsView: View {
    // MARK: - Properties
    
    @StateObject private var viewModel = HealthKitPermissionsViewModel()
    
    /// Callbacks for navigation
    var onContinue: (() -> Void)?
    
    /// Logger for tracking user interactions and errors
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
                    ForEach(viewModel.healthMetrics) { metric in
                        healthDataRow(
                            icon: metric.icon,
                            title: metric.title,
                            description: metric.description,
                            isGranted: metric.isGranted
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
            ProgressIndicator(currentStep: 4, totalSteps: 7)
                .padding(.bottom, 40)
        }
        .withDeepBackground()
        .alert("Health Access Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage)
        }
        .onAppear {
            // Check if permissions were already granted when view appears
            checkExistingPermissions()
        }
        .onChange(of: viewModel.allPermissionsGranted) { _, allGranted in
            if allGranted {
                // Slightly delay continuing to show the granted state to the user
                Task {
                    try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                    await MainActor.run {
                        onContinue?()
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
                    
                    Text(viewModel.isRequestingPermissions ? "Requesting..." : "Allow Health Access")
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
            .accessibilityHint("Request access to health data")
            
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
    
    /// Health data row with icon, text, and status indicator
    private func healthDataRow(icon: String, title: String, description: String, isGranted: Bool) -> some View {
        HStack(spacing: 20) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundColor(isGranted ? .ampedGreen : .ampedSilver)
                .frame(width: 36, height: 36)
                .accessibility(hidden: true)
            
            // Text content
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
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
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title) \(isGranted ? "permission granted" : "permission needed")")
        .accessibilityHint(description)
    }
    
    // MARK: - Helper Methods
    
    /// Check if permissions have already been granted when the view appears
    private func checkExistingPermissions() {
        Task {
            await viewModel.checkPermissionsStatus()
        }
    }
    
    /// Request HealthKit permissions directly from the view
    private func requestHealthKitPermissions() {
        logger.info("User initiating direct HealthKit permission request")
        
        // Create a health store directly
        let healthStore = HKHealthStore()
        
        // Make sure HealthKit is available
        guard HKHealthStore.isHealthDataAvailable() else {
            viewModel.showError(with: "HealthKit is not available on this device.")
            return
        }
        
        viewModel.isRequestingPermissions = true
        
        // Prepare types to read
        var typesToRead = Set<HKObjectType>()
        
        // Add core types we need
        if let stepsType = HKQuantityType.quantityType(forIdentifier: .stepCount) {
            typesToRead.insert(stepsType)
        }
        
        if let heartRateType = HKQuantityType.quantityType(forIdentifier: .restingHeartRate) {
            typesToRead.insert(heartRateType)
        }
        
        if let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) {
            typesToRead.insert(sleepType)
        }
        
        // Request authorization directly - this should trigger the system dialog
        Task {
            do {
                logger.info("Directly requesting HealthKit authorization via HKHealthStore")
                
                // This is the key line that should trigger the iOS permission dialog
                try await healthStore.requestAuthorization(toShare: [], read: typesToRead)
                
                // Wait for the user to interact with the dialog
                try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                
                logger.info("HealthKit authorization request completed")
                
                // Check if permissions were granted
                let granted = typesToRead.allSatisfy { 
                    healthStore.authorizationStatus(for: $0) == .sharingAuthorized 
                }
                
                await MainActor.run {
                    if granted {
                        logger.info("User granted HealthKit permissions")
                        viewModel.updateAllPermissionsGranted(true)
                        
                        // Delay slightly to allow UI to update before continuing
                        Task {
                            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                            await MainActor.run {
                                onContinue?()
                            }
                        }
                    } else {
                        logger.info("User declined HealthKit permissions")
                        viewModel.showError(with: "Health permissions are required to use Amped. Please grant access to continue.")
                    }
                    viewModel.isRequestingPermissions = false
                }
            } catch {
                logger.error("Error requesting HealthKit permissions: \(error.localizedDescription)")
                await MainActor.run {
                    viewModel.showError(with: "Error requesting health permissions: \(error.localizedDescription)")
                    viewModel.isRequestingPermissions = false
                }
            }
        }
    }
}

// MARK: - ViewModel

/// Structure representing a health metric for display
struct HealthMetricDisplay: Identifiable {
    let id = UUID()
    let type: HealthMetricType
    let icon: String
    let title: String
    let description: String
    var isGranted: Bool = false
}

/// ViewModel for the HealthKit permissions view
final class HealthKitPermissionsViewModel: ObservableObject {
    // MARK: - Published Properties
    
    /// Health metrics to display and their permission status
    @Published var healthMetrics: [HealthMetricDisplay] = []
    
    /// UI state properties
    @Published var isRequestingPermissions = false
    @Published var showError = false
    @Published var errorMessage = ""
    @Published var allPermissionsGranted = false
    
    // MARK: - Private Properties
    
    /// HealthKit manager for interacting with HealthKit
    private var healthKitManager: HealthKitManager!
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.amped.Amped", category: "HealthKitPermissionsViewModel")
    
    // MARK: - Initialization
    
    init() {
        // Initialize health metrics display array
        setupHealthMetrics()
        
        // Initialize HealthKit manager on the main actor
        Task { @MainActor in
            self.healthKitManager = HealthKitManager()
        }
    }
    
    // MARK: - Public Methods
    
    /// Check the status of all permissions
    @MainActor
    func checkPermissionsStatus() async {
        guard let healthKitManager = healthKitManager else { return }
        
        if healthKitManager.hasAllPermissions {
            logger.info("HealthKit permissions already granted")
            updateAllPermissionsGranted(true)
        }
    }
    
    /// Request HealthKit permissions
    @MainActor
    func requestHealthKitPermissions() async {
        guard let healthKitManager = healthKitManager else {
            showError(with: "HealthKit manager not initialized yet. Please try again.")
            isRequestingPermissions = false
            return
        }
        
        isRequestingPermissions = true
        
        // Check if HealthKit is available
        guard healthKitManager.isHealthKitAvailable else {
            showError(with: "HealthKit is not available on this device.")
            isRequestingPermissions = false
            return
        }
        
        // Request permissions - this will directly trigger the native iOS permissions dialog
        logger.info("Directly requesting HealthKit authorization to trigger iOS system dialog")
        
        do {
            // Call the authorization method directly - this is what triggers the iOS system dialog
            let granted = await healthKitManager.requestAuthorization()
            logger.info("HealthKit authorization result: \(granted)")
            
            if granted {
                // User granted permissions in the iOS dialog
                updateAllPermissionsGranted(true)
                logger.info("User granted HealthKit permissions")
            } else {
                // User declined permissions in the iOS dialog - since permissions are mandatory, 
                // show an error explaining they need to grant permissions
                logger.info("User declined HealthKit permissions")
                showError(with: "Health permissions are required to use Amped. Please grant access to continue.")
            }
            
            // Set requesting to false to allow trying again
            isRequestingPermissions = false
            
        } catch {
            // An actual error occurred (not just the user declining permissions)
            logger.error("Error requesting HealthKit permissions: \(error.localizedDescription)")
            showError(with: "We encountered an error requesting health permissions. Please try again.")
            isRequestingPermissions = false
        }
    }
    
    // MARK: - Private Methods
    
    /// Initialize the health metrics display data
    private func setupHealthMetrics() {
        healthMetrics = [
            HealthMetricDisplay(
                type: .restingHeartRate,
                icon: "heart.fill",
                title: "Heart Rate",
                description: "Track your resting and active heart rate"
            ),
            HealthMetricDisplay(
                type: .activeEnergyBurned,
                icon: "flame.fill",
                title: "Active Energy",
                description: "Monitor calories burned throughout the day"
            ),
            HealthMetricDisplay(
                type: .sleepHours,
                icon: "bed.double.fill",
                title: "Sleep Analysis",
                description: "Analyze your sleep duration and quality"
            ),
            HealthMetricDisplay(
                type: .steps,
                icon: "figure.walk",
                title: "Steps & Distance",
                description: "Track your daily movement activity"
            ),
            HealthMetricDisplay(
                type: .heartRateVariability,
                icon: "waveform.path.ecg",
                title: "Heart Variability",
                description: "Monitor your heart health and recovery"
            ),
            HealthMetricDisplay(
                type: .vo2Max,
                icon: "lungs.fill",
                title: "Cardio Fitness",
                description: "Track your cardiovascular fitness level"
            )
        ]
    }
    
    /// Update the permission status for all metrics
    func updateAllPermissionsGranted(_ granted: Bool) {
        // Update all metrics
        for i in 0..<healthMetrics.count {
            healthMetrics[i].isGranted = granted
        }
        
        // Update the overall permission status
        allPermissionsGranted = granted
    }
    
    /// Show an error message
    func showError(with message: String) {
        errorMessage = message
        showError = true
    }
}

// MARK: - Preview

struct HealthKitPermissionsView_Previews: PreviewProvider {
    static var previews: some View {
        HealthKitPermissionsView(onContinue: {})
    }
} 