import re

with open("SimpleKeys/ImageCropViewController.swift", "r") as f:
    content = f.read()

new_func = """    @objc private func chooseTapped() {
        let targetHeight: CGFloat = 260
        let targetWidth = view.bounds.width
        let cropY = (view.bounds.height - targetHeight) / 2
        let cropRect = CGRect(x: 0, y: cropY, width: targetWidth, height: targetHeight)
        
        // Hide masks and toolbar temporarily
        topMask.isHidden = true
        bottomMask.isHidden = true
        
        UIGraphicsBeginImageContextWithOptions(cropRect.size, true, 0)
        
        // Translate context so that cropRect's top-left is at (0,0)
        let context = UIGraphicsGetCurrentContext()!
        context.translateBy(x: -cropRect.origin.x, y: -cropRect.origin.y)
        
        // Draw the entire view hierarchy
        view.drawHierarchy(in: view.bounds, afterScreenUpdates: true)
        
        let croppedImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        // Restore masks
        topMask.isHidden = false
        bottomMask.isHidden = false
        
        onCrop?(croppedImage)
        dismiss(animated: true, completion: nil)
    }"""

content = re.sub(r'    @objc private func chooseTapped\(\) \{.*?(?=\n    \})\n    \}', new_func, content, flags=re.DOTALL)

with open("SimpleKeys/ImageCropViewController.swift", "w") as f:
    f.write(content)
