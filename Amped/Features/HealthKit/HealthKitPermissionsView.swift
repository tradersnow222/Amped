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
            // Back button
            HStack {
                Button(action: {
                    // Handle back action
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.gray)
                        .padding()
                }
                Spacer()
            }
            .padding(.top, 8)
            
            // Spacer with flex to position content at rule of thirds
            Spacer()
                .frame(height: UIScreen.main.bounds.height * 0.1)
            
            // 3D Heart Icon
            ZStack {
                // White rounded square with shadow
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.white)
                    .frame(width: 120, height: 120)
                    .shadow(color: Color.white.opacity(0.1), radius: 15, x: 0, y: 8)
                    .shadow(color: Color.white.opacity(0.05), radius: 5, x: 0, y: 3)
                    .rotationEffect(.degrees(10))
                
                // Heart icon
                Image(systemName: "heart.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 50, height: 50)
                    .foregroundColor(Color.ampedRed)
                    .shadow(color: Color.ampedRed.opacity(0.3), radius: 4, x: 0, y: 2)
                    .rotationEffect(.degrees(10))
            }
            .padding(.bottom, 40)
            
            // Concise health description text
            Text("Connect your health data to power your life battery")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .padding(.bottom, 16)
                
            Text("See the direct impact of your daily habits on your lifespan")
                .font(.system(size: 17))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            // Flexible spacing
            Spacer(minLength: 60)
            
            // Continue button
            Button(action: requestHealthKitPermissions) {
                HStack {
                    if viewModel.isRequestingPermissions {
                        ProgressView()
                            .tint(.white)
                            .scaleEffect(0.8)
                            .padding(.trailing, 6)
                    } else {
                        Image(systemName: "heart.fill")
                            .foregroundColor(.white)
                            .font(.system(size: 16))
                            .padding(.trailing, 4)
                    }
                    
                    Text(viewModel.isRequestingPermissions ? "Requesting..." : "Continue")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    Capsule()
                        .fill(viewModel.isRequestingPermissions ? Color.gray : Color.ampedGreen)
                )
                .padding(.horizontal, 40)
            }
            .disabled(viewModel.isRequestingPermissions || viewModel.allPermissionsGranted)
            .hapticFeedback()
            .padding(.bottom, 40)
            
            // Home indicator area
            Rectangle()
                .frame(width: 134, height: 5)
                .cornerRadius(2.5)
                .foregroundColor(.white.opacity(0.2))
                .padding(.bottom, 8)
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
        // Monitor for iOS health permission dialog return
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            logger.info("App became active again - likely returned from Health permission dialog")
            Task {
                // Skip waiting and immediately check for permissions
                logger.info("Checking permissions status after app becomes active")
                await viewModel.checkPermissionsStatus(forceRefresh: true)
                
                // If permissions are granted, proceed to the next screen
                if viewModel.allPermissionsGranted || viewModel.criticalPermissionsGranted {
                    logger.info("Permissions detected after returning from system dialog, continuing")
                    onContinue?()
                } else {
                    logger.info("Permissions not detected by status check, trying direct data access validation")
                    
                    // Create a new HealthKit manager with a fresh store to avoid any caching issues
                    let healthKitManager = HealthKitManager()
                    
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
    
    // MARK: - Helper Methods
    
    /// Helper method to check permissions and continue if granted
    private func checkPermissionsAndContinue() async {
        // Clear any error state to be safe
        viewModel.clearErrorState()
        
        // Check permissions to ensure the UI is updated
        await viewModel.checkPermissionsStatus(forceRefresh: true)
        
        // Important: Call onContinue on the main thread
        DispatchQueue.main.async {
            self.onContinue?()
        }
    }
    
    /// Check if permissions were already granted
    private func checkExistingPermissions() {
        Task {
            logger.debug("Checking existing HealthKit permissions")
            await viewModel.checkPermissionsStatus()
            
            if viewModel.allPermissionsGranted || viewModel.criticalPermissionsGranted {
                logger.info("Existing permissions already granted")
                DispatchQueue.main.async {
                    self.onContinue?()
                }
            } else {
                logger.debug("Permissions not yet granted, staying on permissions screen")
            }
        }
    }
    
    /// Request HealthKit permissions
    private func requestHealthKitPermissions() {
        logger.info("User initiating HealthKit permission request")
        viewModel.clearErrorState()

        Task {
            // Request permissions and wait for the result
            let success = await viewModel.requestHealthKitPermissions()
            
            if success {
                logger.info("HealthKit permissions request successful")
                await checkPermissionsAndContinue()
            } else {
                logger.warning("HealthKit permissions request failed or was rejected")
                // Add a final retry check after a delay - sometimes iOS updates permissions asynchronously
                // and the immediate check in requestHealthKitPermissions might miss it
                try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
                logger.info("Checking permission status after explicit request")
                await viewModel.checkPermissionsStatus(forceRefresh: true)
                
                // Check again if permissions are valid after our explicit refresh
                if viewModel.allPermissionsGranted || viewModel.criticalPermissionsGranted {
                    logger.info("Delayed permission check successful - proceeding")
                    await checkPermissionsAndContinue()
                } else {
                    logger.warning("HealthKit permissions not detected by status check, trying data access validation")
                    
                    // Create a fresh HealthKit manager to avoid any caching issues
                    let healthKitManager = HealthKitManager()
                    
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
                        
                        // One final check with a doubled delay - iOS can be very slow to update permissions
                        try? await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds
                        await viewModel.checkPermissionsStatus(forceRefresh: true)
                        
                        if viewModel.allPermissionsGranted || viewModel.criticalPermissionsGranted {
                            logger.info("Final delayed permission check successful - proceeding")
                            DispatchQueue.main.async {
                                self.onContinue?()
                            }
                        }
                    }
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