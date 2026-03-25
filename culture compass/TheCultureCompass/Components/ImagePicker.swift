import SwiftUI
import PhotosUI

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var imageData: Data?
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(imageData: $imageData)
    }

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        @Binding var imageData: Data?

        init(imageData: Binding<Data?>) {
            _imageData = imageData
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            guard let provider = results.first?.itemProvider,
                  provider.canLoadObject(ofClass: UIImage.self) else {
                picker.dismiss(animated: true)
                return
            }
            provider.loadObject(ofClass: UIImage.self) { image, _ in
                DispatchQueue.main.async {
                    if let uiImage = image as? UIImage {
                        self.imageData = uiImage.jpegData(compressionQuality: 0.7)
                    }
                    picker.dismiss(animated: true)
                }
            }
        }
    }
}
