import SwiftUI
import PhotosUI
import OSLog

/// Photo picker view for selecting profile images
struct PhotoPickerView: View {
    @StateObject private var viewModel = DashboardViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var selectedItem: PhotosPickerItem?
    @State private var showingActionSheet = false
    @State private var showingImagePicker = false
    @State private var showingCamera = false
    @State private var sourceType: UIImagePickerController.SourceType = .photoLibrary
    
    private let logger = Logger(subsystem: "ai.ampedlife.amped", category: "PhotoPicker")
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Current profile image
                VStack(spacing: 16) {
                    ProfileImageView(size: 120, showBorder: true, showEditIndicator: false, userProfile: viewModel.userProfile)
                    
                    Text("Profile Photo")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                }
                .padding(.top, 40)
                
                Spacer()
                
                // Action buttons
                VStack(spacing: 16) {
                    // Choose Photo button
                    Button {
                        showingActionSheet = true
                    } label: {
                        HStack {
                            Image(systemName: "photo.on.rectangle")
                                .font(.title3)
                            Text("Choose Photo")
                                .font(.headline)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .cornerRadius(12)
                    }
                    
                    // Remove Photo button (only show if user has a profile image)
                    if ProfileImageManager.shared.profileImage != nil {
                        Button {
                            removePhoto()
                        } label: {
                            HStack {
                                Image(systemName: "trash")
                                    .font(.title3)
                                Text("Remove Photo")
                                    .font(.headline)
                            }
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
            .navigationTitle("Edit Photo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.accentColor)
                }
            }
            .confirmationDialog("Choose Photo", isPresented: $showingActionSheet) {
                Button("Camera") {
                    if UIImagePickerController.isSourceTypeAvailable(.camera) {
                        sourceType = .camera
                        showingImagePicker = true
                    }
                }
                
                Button("Photo Library") {
                    sourceType = .photoLibrary
                    showingImagePicker = true
                }
                
                Button("Cancel", role: .cancel) { }
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(sourceType: sourceType) { image in
                    saveSelectedImage(image)
                }
            }
        }
    }
    
    private func removePhoto() {
        ProfileImageManager.shared.removeProfileImage()
        logger.info("Profile photo removed")
        dismiss()
    }
    
    private func saveSelectedImage(_ image: UIImage) {
        ProfileImageManager.shared.saveProfileImage(image)
        logger.info("Profile photo updated")
        dismiss()
    }
}

// MARK: - Image Picker Wrapper

struct ImagePicker: UIViewControllerRepresentable {
    let sourceType: UIImagePickerController.SourceType
    let onImageSelected: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        picker.allowsEditing = true
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let editedImage = info[.editedImage] as? UIImage {
                parent.onImageSelected(editedImage)
            } else if let originalImage = info[.originalImage] as? UIImage {
                parent.onImageSelected(originalImage)
            }
            
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

#Preview {
    PhotoPickerView()
}
