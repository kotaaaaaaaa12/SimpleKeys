import UIKit
import Foundation
import ImageIO

extension String {
    func toKatakana() -> String {
        return self.applyingTransform(.hiraganaToKatakana, reverse: false) ?? self
    }
    
    func toHalfWidth() -> String {
        return self.applyingTransform(.fullwidthToHalfwidth, reverse: false) ?? self
    }
    
    func toFullWidth() -> String {
        return self.applyingTransform(.fullwidthToHalfwidth, reverse: true) ?? self
    }
}

// MARK: - AppGroupHelper
class AppGroupHelper {
    static let shared = AppGroupHelper()
    
    private(set) var appGroupID: String = "group.com.simplekeys.app"
    private(set) var userDefaults: UserDefaults?
    
    private init() {
        if let group = resolveAppGroup() {
            self.appGroupID = group
        }
        self.userDefaults = UserDefaults(suiteName: self.appGroupID)
    }
    
    private func resolveAppGroup() -> String? {
        guard let path = Bundle.main.path(forResource: "embedded", ofType: "mobileprovision"),
              let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
              let string = String(data: data, encoding: .isoLatin1) else {
            return nil
        }
        
        if let startRange = string.range(of: "<?xml"),
           let endRange = string.range(of: "</plist>") {
            let plistString = String(string[startRange.lowerBound...endRange.upperBound])
            if let plistData = plistString.data(using: .utf8),
               let plist = try? PropertyListSerialization.propertyList(from: plistData, options: [], format: nil) as? [String: Any],
               let entitlements = plist["Entitlements"] as? [String: Any],
               let appGroups = entitlements["com.apple.security.application-groups"] as? [String],
               let firstGroup = appGroups.first {
                return firstGroup
            }
        }
        return nil
    }
    
    func containerURL() -> URL? {
        return FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID)
    }
    
    func saveImage(_ image: UIImage, fileName: String) -> Bool {
        guard let data = image.jpegData(compressionQuality: 0.8) else { return false }
        guard let url = containerURL()?.appendingPathComponent(fileName) else { return false }
        do {
            try data.write(to: url)
            return true
        } catch {
            print("Failed to save image: \(error)")
            return false
        }
    }
    
    func saveFile(from sourceURL: URL, fileName: String) -> Bool {
        guard let dest = containerURL()?.appendingPathComponent(fileName) else { return false }
        do {
            if FileManager.default.fileExists(atPath: dest.path) {
                try FileManager.default.removeItem(at: dest)
            }
            try FileManager.default.copyItem(at: sourceURL, to: dest)
            return true
        } catch {
            print("Failed to save file: \(error)")
            return false
        }
    }
    
    func fileURL(for fileName: String) -> URL? {
        return containerURL()?.appendingPathComponent(fileName)
    }
    
    func loadImage(fileName: String) -> UIImage? {
        guard let url = containerURL()?.appendingPathComponent(fileName) else { return nil }
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageIfAbsent: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceThumbnailMaxPixelSize: 800
        ]
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
            return nil
        }
        return UIImage(cgImage: cgImage)
    }
    
    func loadGIF(fileName: String) -> UIImage? {
        guard let url = containerURL()?.appendingPathComponent(fileName) else { return nil }
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }
        
        var images = [UIImage]()
        let count = CGImageSourceGetCount(source)
        var totalDuration: Double = 0
        
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageIfAbsent: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceThumbnailMaxPixelSize: 800
        ]
        
        // Skip frames if there are too many to save memory (max 30 frames)
        let step = max(1, count / 30)
        
        for i in stride(from: 0, to: count, by: step) {
            if let cgImage = CGImageSourceCreateThumbnailAtIndex(source, i, options as CFDictionary) {
                images.append(UIImage(cgImage: cgImage))
                
                var delay = 0.1
                if let properties = CGImageSourceCopyPropertiesAtIndex(source, i, nil) as? [String: Any],
                   let gifInfo = properties[kCGImagePropertyGIFDictionary as String] as? [String: Any] {
                    if let delayTime = gifInfo[kCGImagePropertyGIFUnclampedDelayTime as String] as? Double {
                        delay = delayTime
                    } else if let delayTime = gifInfo[kCGImagePropertyGIFDelayTime as String] as? Double {
                        delay = delayTime
                    }
                }
                totalDuration += delay * Double(step)
            }
        }
        
        if totalDuration == 0 {
            totalDuration = Double(count) * 0.1
        }
        
        return UIImage.animatedImage(with: images, duration: totalDuration)
    }
    
    func removeImage(fileName: String) {
        guard let url = containerURL()?.appendingPathComponent(fileName) else { return }
        try? FileManager.default.removeItem(at: url)
    }
    
    func saveCustomThemeSettings(_ theme: ThemeSettings) {
        if let data = try? JSONEncoder().encode(theme) {
            userDefaults?.set(data, forKey: ThemeSettings.sharedKey)
        }
    }
    
    func loadCustomThemeSettings() -> ThemeSettings? {
        if let data = userDefaults?.data(forKey: ThemeSettings.sharedKey),
           let theme = try? JSONDecoder().decode(ThemeSettings.self, from: data) {
            return theme
        }
        return nil
    }
}

// MARK: - Theme Models
struct ThemeSettings: Codable, Equatable {
    var id: String?
    var name: String?
    var backgroundImageFileName: String?
    var backgroundColorHex: String?
    var keyStyle: Int // 0: standard, 1: frosted glass, 2: flat, 3: clear glass
    var buttonShape: Int? // 0: rounded, 1: oval, 2: rect
    var fontName: String?
    var keyColorHex: String?
    var textColorHex: String?
    var keyBorderColorHex: String?
    var keyOpacity: CGFloat?
    var flickPopupBgHex: String?       // Flick popup background color
    var flickPopupTextHex: String?     // Flick popup text color
    var flickHighlightHex: String?     // Highlight color for flick hints
    var flickPopupShape: Int?          // 0: rounded, 1: oval, 2: rect
    var flickPopupBorderColorHex: String?
    var flickPopupBorderWidth: CGFloat?
    var flickPopupBorderStyle: Int?    // 0: solid, 1: dashed, 2: dotted, 3: double, 4: dash-dot, 5: dash-dot-dot
    var videoAudioEnabled: Bool?       // Toggle for video background audio
    var keyBorderWidth: CGFloat?
    var keyBorderStyle: Int? // 0: solid, 1: dashed, 2: dotted, 3: double, 4: dash-dot, 5: dash-dot-dot
    
    static let sharedKey = "customThemeSettings"
    static let themesArrayKey = "savedCustomThemes"
}

extension UIColor {
    convenience init?(hex: String) {
        var hexString = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if hexString.hasPrefix("#") {
            hexString.remove(at: hexString.startIndex)
        }
        if hexString.count != 6 && hexString.count != 8 { return nil }
        var rgbValue: UInt64 = 0
        Scanner(string: hexString).scanHexInt64(&rgbValue)
        if hexString.count == 6 {
            self.init(red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
                      green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
                      blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
                      alpha: 1.0)
        } else {
            self.init(red: CGFloat((rgbValue & 0xFF000000) >> 24) / 255.0,
                      green: CGFloat((rgbValue & 0x00FF0000) >> 16) / 255.0,
                      blue: CGFloat((rgbValue & 0x0000FF00) >> 8) / 255.0,
                      alpha: CGFloat(rgbValue & 0x000000FF) / 255.0)
        }
    }
}

extension UIView {
    func applyCustomBorderStyle(width: CGFloat, style: Int, color: CGColor?, radius: CGFloat, isFrostedOrClear: Bool) {
        // Remove existing custom border layers
        self.layer.sublayers?.filter { $0.name == "customBorderLayer" }.forEach { $0.removeFromSuperlayer() }
        
        if width == 0 || color == nil {
            self.layer.borderWidth = 0
            return
        }
        
        let cgColor = color!
        
        if style == 0 {
            // Solid line
            self.layer.borderWidth = width
            self.layer.borderColor = cgColor
            self.layer.cornerRadius = radius
            return
        }
        
        // Hide native border for non-solid
        self.layer.borderWidth = 0
        self.layer.cornerRadius = radius
        
        let borderLayer = CAShapeLayer()
        borderLayer.name = "customBorderLayer"
        let path = UIBezierPath(roundedRect: self.bounds, cornerRadius: radius)
        
        borderLayer.path = path.cgPath
        borderLayer.fillColor = UIColor.clear.cgColor
        borderLayer.strokeColor = cgColor
        borderLayer.lineWidth = width
        
        switch style {
        case 1: // Dashed
            borderLayer.lineDashPattern = [NSNumber(value: Float(width * 3)), NSNumber(value: Float(width * 2))]
        case 2: // Dotted
            borderLayer.lineDashPattern = [NSNumber(value: Float(width)), NSNumber(value: Float(width * 2))]
            borderLayer.lineCap = .round
            borderLayer.lineJoin = .round
        case 3: // Double
            let outerLayer = CAShapeLayer()
            outerLayer.path = UIBezierPath(roundedRect: self.bounds.insetBy(dx: width/3, dy: width/3), cornerRadius: max(0, radius - width/3)).cgPath
            outerLayer.strokeColor = cgColor
            outerLayer.fillColor = UIColor.clear.cgColor
            outerLayer.lineWidth = width / 3.0
            
            let innerLayer = CAShapeLayer()
            innerLayer.path = UIBezierPath(roundedRect: self.bounds.insetBy(dx: -width/3, dy: -width/3), cornerRadius: radius + width/3).cgPath
            innerLayer.strokeColor = cgColor
            innerLayer.fillColor = UIColor.clear.cgColor
            innerLayer.lineWidth = width / 3.0
            
            let parentLayer = CALayer()
            parentLayer.name = "customBorderLayer"
            parentLayer.frame = self.bounds
            parentLayer.addSublayer(outerLayer)
            parentLayer.addSublayer(innerLayer)
            self.layer.addSublayer(parentLayer)
            return
        case 4: // Dash-Dot
            borderLayer.lineDashPattern = [NSNumber(value: Float(width * 4)), NSNumber(value: Float(width * 2)), NSNumber(value: Float(width)), NSNumber(value: Float(width * 2))]
        case 5: // Dash-Dot-Dot
            borderLayer.lineDashPattern = [NSNumber(value: Float(width * 4)), NSNumber(value: Float(width * 2)), NSNumber(value: Float(width)), NSNumber(value: Float(width * 2)), NSNumber(value: Float(width)), NSNumber(value: Float(width * 2))]
        default: break
        }
        
        self.layer.addSublayer(borderLayer)
    }
}
