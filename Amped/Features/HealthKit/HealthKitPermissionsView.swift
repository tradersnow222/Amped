import SwiftUI
import HealthKit

/// View for requesting HealthKit permissions
struct HealthKitPermissionsView: View {
    // MARK: - Properties
    
    @StateObject private var viewModel = HealthKitPermissionsViewModel()
    
    // Callback to proceed to next step
    var onContinue: (() -> Void)?
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Health Access")
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.top, 40)
            
            Text("Allow Amped to access health data to calculate your life battery")
                .font(.headline)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Spacer()
            
            // Health metrics list
            VStack(alignment: .leading, spacing: 24) {
                healthDataRow(
                    icon: "heart.fill",
                    title: "Heart Rate",
                    description: "Track your resting and active heart rate"
                )
                
                healthDataRow(
                    icon: "flame.fill",
                    title: "Active Energy",
                    description: "Monitor calories burned throughout the day"
                )
                
                healthDataRow(
                    icon: "bed.double.fill",
                    title: "Sleep Analysis",
                    description: "Analyze your sleep duration and quality"
                )
                
                healthDataRow(
                    icon: "figure.walk",
                    title: "Steps & Distance",
                    description: "Track your daily movement activity"
                )
            }
            .padding(.horizontal, 30)
            
            Spacer()
            
            // Permissions button
            Button(action: {
                requestHealthKitPermissions()
            }) {
                Text(viewModel.isRequestingPermissions ? "Requesting..." : "Allow Health Access")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(viewModel.isRequestingPermissions ? Color.gray : Color.ampedGreen)
                    .foregroundColor(.white)
                    .cornerRadius(14)
            }
            .disabled(viewModel.isRequestingPermissions)
            .padding(.horizontal, 40)
            .padding(.bottom, 30)
            .hapticFeedback()
            
            // Progress indicator
            ProgressIndicator(currentStep: 4, totalSteps: 7)
                .padding(.bottom, 40)
        }
        .withDeepBackground()
        .alert(isPresented: $viewModel.showError) {
            Alert(
                title: Text("Health Access Error"),
                message: Text(viewModel.errorMessage),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    // MARK: - Helper Methods
    
    private func requestHealthKitPermissions() {
        viewModel.isRequestingPermissions = true
        
        Task {
            // Check if HealthKit is available
            guard viewModel.healthKitManager.isHealthKitAvailable else {
                viewModel.errorMessage = "HealthKit is not available on this device."
                viewModel.showError = true
                viewModel.isRequestingPermissions = false
                return
            }
            
            // Request permissions
            let granted = await viewModel.healthKitManager.requestAuthorization()
            
            if granted {
                // Update UI to show all permissions granted
                viewModel.activityPermissionGranted = true
                viewModel.heartPermissionGranted = true
                viewModel.sleepPermissionGranted = true
                viewModel.fitnessPermissionGranted = true
                
                // Proceed to next step
                onContinue?()
            } else {
                viewModel.errorMessage = "We need these permissions to provide accurate insights. Please try again."
                viewModel.showError = true
            }
            
            viewModel.isRequestingPermissions = false
        }
    }
    
    // MARK: - UI Components
    
    /// Health data row with icon and text
    private func healthDataRow(icon: String, title: String, description: String) -> some View {
        HStack(spacing: 20) {
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundColor(.ampedGreen)
                .frame(width: 36, height: 36)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

// MARK: - ViewModel

@MainActor
final class HealthKitPermissionsViewModel: ObservableObject {
    // Permission states
    @Published var activityPermissionGranted = false
    @Published var heartPermissionGranted = false
    @Published var sleepPermissionGranted = false
    @Published var fitnessPermissionGranted = false
    
    // UI states
    @Published var isRequestingPermissions = false
    @Published var showError = false
    @Published var errorMessage = ""
    
    // HealthKit manager
    let healthKitManager: HealthKitManager
    
    init() {
        self.healthKitManager = HealthKitManager()
    }
}

// MARK: - Preview

struct HealthKitPermissionsView_Previews: PreviewProvider {
    static var previews: some View {
        HealthKitPermissionsView(onContinue: {})
    }
} 