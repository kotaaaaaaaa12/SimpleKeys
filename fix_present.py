import re

with open("SimpleKeys/SimpleKeys/ViewController.swift", "r") as f:
    content = f.read()

old_str = """        picker.dismiss(animated: true)
        if let image = info[.originalImage] as? UIImage {
            let cropVC = ImageCropViewController()
            cropVC.originalImage = image
            cropVC.onCrop = { [weak self] croppedImage in
                guard let self = self else { return }
                let fileName = "\\(UUID().uuidString).jpg"
                if AppGroupHelper.shared.saveImage(croppedImage, fileName: fileName) {
                    self.currentTheme.backgroundImageFileName = fileName
                    self.updatePreview()
                }
            }
            cropVC.modalPresentationStyle = .fullScreen
            present(cropVC, animated: true)
        }"""

new_str = """        if let image = info[.originalImage] as? UIImage {
            picker.dismiss(animated: true) { [weak self] in
                let cropVC = ImageCropViewController()
                cropVC.originalImage = image
                cropVC.onCrop = { [weak self] croppedImage in
                    guard let self = self else { return }
                    let fileName = "\\(UUID().uuidString).jpg"
                    if AppGroupHelper.shared.saveImage(croppedImage, fileName: fileName) {
                        self.currentTheme.backgroundImageFileName = fileName
                        self.updatePreview()
                    }
                }
                cropVC.modalPresentationStyle = .fullScreen
                self?.present(cropVC, animated: true)
            }
        } else {
            picker.dismiss(animated: true)
        }"""

content = content.replace(old_str, new_str)

with open("SimpleKeys/SimpleKeys/ViewController.swift", "w") as f:
    f.write(content)
