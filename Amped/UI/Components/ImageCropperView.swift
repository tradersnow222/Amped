import SwiftUI
import SwiftyCrop

struct ImageCropperView: View {
    let image: UIImage
    let onCrop: (UIImage) -> Void
    let onCancel: () -> Void
    
    var body: some View {
        SwiftyCropView(
            imageToCrop: image,
            maskShape: .circle
        ) { croppedImage in
            if let croppedImage = croppedImage {
                onCrop(croppedImage)
            }
        }
    }
}

#Preview {
    ImageCropperView(
        image: UIImage(systemName: "person.circle.fill")!,
        onCrop: { _ in },
        onCancel: { }
    )
}
