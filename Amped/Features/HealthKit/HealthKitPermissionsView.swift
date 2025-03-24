import SwiftUI
import HealthKit

/// View for requesting HealthKit permissions
struct HealthKitPermissionsView: View {
    // MARK: - Properties
    
    @StateObject private var viewModel = HealthKitPermissionsViewModel()
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 24) {
            // Title
            Text("Power Your Insights")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top, 30)
                .padding(.bottom, 10)
            
            // Description
            Text("Amped needs access to your health data to calculate your life impact and provide personalized insights.")
                .font(.headline)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)
            
            // Permissions list
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    permissionRow(
                        icon: "figure.walk",
                        title: "Physical Activity",
                        description: "Steps, exercise minutes, and active energy",
                        isGranted: viewModel.activityPermissionGranted
                    )
                    
                    permissionRow(
                        icon: "heart.fill",
                        title: "Heart Health",
                        description: "Resting heart rate and heart rate variability",
                        isGranted: viewModel.heartPermissionGranted
                    )
                    
                    permissionRow(
                        icon: "bed.double.fill",
                        title: "Sleep",
                        description: "Sleep duration and quality",
                        isGranted: viewModel.sleepPermissionGranted
                    )
                    
                    permissionRow(
                        icon: "lungs.fill",
                        title: "Cardiovascular Fitness",
                        description: "VO2 max data",
                        isGranted: viewModel.fitnessPermissionGranted
                    )
                }
                .padding(.horizontal, 30)
            }
            
            Spacer()
            
            // Privacy note
            VStack(spacing: 8) {
                Text("Your privacy is our priority")
                    .font(.headline)
                
                Text("All health data processing happens on your device. We never share your health data with third parties.")
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 40)
            }
            
            Spacer()
            
            // Grant access button
            Button(action: {
                viewModel.requestHealthKitPermissions()
            }) {
                HStack {
                    Image(systemName: "lock.shield.fill")
                    Text("Allow Health Access")
                }
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.ampedGreen)
                .foregroundColor(.white)
                .cornerRadius(14)
            }
            .padding(.horizontal, 30)
            .opacity(viewModel.isRequestingPermissions ? 0.5 : 1.0)
            .disabled(viewModel.isRequestingPermissions)
            .overlay(
                Group {
                    if viewModel.isRequestingPermissions {
                        ProgressView()
                    }
                }
            )
            
            // Progress indicator
            ProgressIndicator(currentStep: 4, totalSteps: 7)
                .padding(.vertical, 30)
        }
        .alert(isPresented: $viewModel.showError) {
            Alert(
                title: Text("Permission Error"),
                message: Text(viewModel.errorMessage),
                dismissButton: .default(Text("OK"))
            )
        }
        .background(Color(.systemBackground))
        .fullScreenCover(isPresented: $viewModel.showSignInWithApple) {
            // This would lead to Sign in with Apple screen
            SignInWithAppleView()
        }
    }
    
    // MARK: - UI Components
    
    /// Permission row with icon, title, description, and status
    private func permissionRow(icon: String, title: String, description: String, isGranted: Bool) -> some View {
        HStack(spacing: 16) {
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
            
            // Status indicator
            Image(systemName: isGranted ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isGranted ? .ampedGreen : .gray)
                .font(.system(size: 24))
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
    
    // Navigation
    @Published var showSignInWithApple = false
    
    // HealthKit manager
    @ObservedObject private var healthKitManager: HealthKitManager
    
    init() {
        self.healthKitManager = HealthKitManager()
    }
    
    // Request HealthKit permissions
    func requestHealthKitPermissions() {
        isRequestingPermissions = true
        
        Task {
            // Check if HealthKit is available
            guard healthKitManager.isHealthKitAvailable else {
                errorMessage = "HealthKit is not available on this device."
                showError = true
                isRequestingPermissions = false
                return
            }
            
            // Request permissions
            let granted = await healthKitManager.requestAuthorization()
            
            if granted {
                // Update UI to show all permissions granted
                activityPermissionGranted = true
                heartPermissionGranted = true
                sleepPermissionGranted = true
                fitnessPermissionGranted = true
                
                // Proceed to next step
                showSignInWithApple = true
            } else {
                errorMessage = "We need these permissions to provide accurate insights. Please try again."
                showError = true
            }
            
            isRequestingPermissions = false
        }
    }
}

// MARK: - Preview

struct HealthKitPermissionsView_Previews: PreviewProvider {
    static var previews: some View {
        HealthKitPermissionsView()
    }
} 