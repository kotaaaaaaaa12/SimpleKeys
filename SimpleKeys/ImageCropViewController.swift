import UIKit

class ImageCropViewController: UIViewController, UIScrollViewDelegate {
    
    var originalImage: UIImage!
    var onCrop: ((UIImage) -> Void)?
    
    private let scrollView = UIScrollView()
    private let imageView = UIImageView()
    private let cropMaskView = UIView()
    private let topMask = UIView()
    private let bottomMask = UIView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        
        let targetHeight: CGFloat = 260
        let targetWidth = view.bounds.width
        
        scrollView.delegate = self
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.bounces = true
        scrollView.alwaysBounceVertical = true
        scrollView.alwaysBounceHorizontal = true
        
        imageView.image = originalImage
        imageView.contentMode = .scaleAspectFill
        scrollView.addSubview(imageView)
        view.addSubview(scrollView)
        
        // Add semi-transparent masks to show the cropping area
        topMask.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        bottomMask.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        view.addSubview(topMask)
        view.addSubview(bottomMask)
        
        // Set up buttons
        let toolbar = UIToolbar()
        toolbar.translatesAutoresizingMaskIntoConstraints = false
        toolbar.barStyle = .black
        toolbar.isTranslucent = true
        view.addSubview(toolbar)
        
        let cancelBtn = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(cancelTapped))
        let flex = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let chooseBtn = UIBarButtonItem(title: "Choose", style: .done, target: self, action: #selector(chooseTapped))
        toolbar.items = [cancelBtn, flex, chooseBtn]
        
        // Layout
        let cropY = (view.bounds.height - targetHeight) / 2
        let cropRect = CGRect(x: 0, y: cropY, width: targetWidth, height: targetHeight)
        
        scrollView.frame = view.bounds
        topMask.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: cropRect.minY)
        bottomMask.frame = CGRect(x: 0, y: cropRect.maxY, width: view.bounds.width, height: view.bounds.height - cropRect.maxY)
        
        // Configure ScrollView insets so the image can be panned within the crop rect
        scrollView.contentInset = UIEdgeInsets(top: cropRect.minY, left: 0, bottom: view.bounds.height - cropRect.maxY, right: 0)
        
        let imgSize = originalImage.size
        let aspect = imgSize.width / imgSize.height
        let viewAspect = targetWidth / targetHeight
        
        var startWidth: CGFloat = 0
        var startHeight: CGFloat = 0
        
        if aspect > viewAspect {
            // Image is wider
            startHeight = targetHeight
            startWidth = startHeight * aspect
        } else {
            // Image is taller
            startWidth = targetWidth
            startHeight = startWidth / aspect
        }
        
        imageView.frame = CGRect(x: 0, y: 0, width: startWidth, height: startHeight)
        scrollView.contentSize = imageView.frame.size
        
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 4.0
        scrollView.zoomScale = 1.0
        
        // Center the image initially
        let offsetX = (startWidth - targetWidth) / 2
        let offsetY = (startHeight - targetHeight) / 2
        scrollView.contentOffset = CGPoint(x: offsetX, y: offsetY - cropRect.minY)
        
        NSLayoutConstraint.activate([
            toolbar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            toolbar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            toolbar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    @objc private func cancelTapped() {
        dismiss(animated: true, completion: nil)
    }
    
    @objc private func chooseTapped() {
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
    }
}
