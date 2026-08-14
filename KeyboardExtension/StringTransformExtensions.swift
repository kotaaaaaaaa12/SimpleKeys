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
    func applyCustomBorderStyle(width: CGFloat, style: Int, color: CGColor?, radius: CGFloat, isFrostedOrClear: Bool, shape: Int = 0) {
        // Remove existing custom border layers
        self.layer.sublayers?.filter { $0.name == "customBorderLayer" }.forEach { $0.removeFromSuperlayer() }
        
        if width == 0 || color == nil {
            self.layer.borderWidth = 0
            return
        }
        
        let cgColor = color!
        
        if style == 0 && shape < 3 {
            // Solid line
            self.layer.borderWidth = width
            self.layer.borderColor = cgColor
            self.layer.cornerRadius = radius
            return
        }
        
        // Hide native border for non-solid or custom shape
        self.layer.borderWidth = 0
        if shape < 3 {
            self.layer.cornerRadius = radius
        }
        
        let borderLayer = CAShapeLayer()
        borderLayer.name = "customBorderLayer"
        
        let path = shape >= 3 ? UIBezierPath.customShape(type: shape, in: self.bounds) : UIBezierPath(roundedRect: self.bounds, cornerRadius: radius)
        
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
            let innerRect = self.bounds.insetBy(dx: width/3, dy: width/3)
            let outerPath = shape >= 3 ? UIBezierPath.customShape(type: shape, in: innerRect).cgPath : UIBezierPath(roundedRect: innerRect, cornerRadius: max(0, radius - width/3)).cgPath
            
            let outerLayer = CAShapeLayer()
            outerLayer.path = outerPath
            outerLayer.strokeColor = cgColor
            outerLayer.fillColor = UIColor.clear.cgColor
            outerLayer.lineWidth = width / 3.0
            
            let innerInnerRect = self.bounds.insetBy(dx: -width/3, dy: -width/3)
            let innerPath = shape >= 3 ? UIBezierPath.customShape(type: shape, in: innerInnerRect).cgPath : UIBezierPath(roundedRect: innerInnerRect, cornerRadius: radius + width/3).cgPath
            
            let innerLayer = CAShapeLayer()
            innerLayer.path = innerPath
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


import UIKit

extension UIBezierPath {
    static func star(in rect: CGRect) -> UIBezierPath {
        let path = UIBezierPath()
        let pts = 5
        for i in 0..<(pts * 2) {
            let radius: CGFloat = i % 2 == 0 ? 1.0 : 0.4
            let angle = CGFloat(i) * .pi / CGFloat(pts) - .pi / 2
            let p = CGPoint(x: radius * cos(angle), y: radius * sin(angle))
            if i == 0 { path.move(to: p) }
            else { path.addLine(to: p) }
        }
        path.close()
        return scaleToFit(path: path, in: rect)
    }
    
    static func triangle(in rect: CGRect) -> UIBezierPath {
        let path = UIBezierPath()
        path.move(to: CGPoint(x: 0, y: -1))
        path.addLine(to: CGPoint(x: 1, y: 1))
        path.addLine(to: CGPoint(x: -1, y: 1))
        path.close()
        return scaleToFit(path: path, in: rect)
    }
    
    static func pentagon(in rect: CGRect) -> UIBezierPath {
        let path = UIBezierPath()
        for i in 0..<5 {
            let angle = CGFloat(i) * 2 * .pi / 5 - .pi / 2
            let p = CGPoint(x: cos(angle), y: sin(angle))
            if i == 0 { path.move(to: p) }
            else { path.addLine(to: p) }
        }
        path.close()
        return scaleToFit(path: path, in: rect)
    }
    
    static func hexagon(in rect: CGRect) -> UIBezierPath {
        let path = UIBezierPath()
        for i in 0..<6 {
            let angle = CGFloat(i) * 2 * .pi / 6 - .pi / 2
            let p = CGPoint(x: cos(angle), y: sin(angle))
            if i == 0 { path.move(to: p) }
            else { path.addLine(to: p) }
        }
        path.close()
        return scaleToFit(path: path, in: rect)
    }
    
    static func speechBubble(in rect: CGRect) -> UIBezierPath {
        let path = UIBezierPath()
        let r: CGFloat = 8
        let tailWidth: CGFloat = 12
        let tailHeight: CGFloat = 8
        let bubbleRect = CGRect(x: rect.minX, y: rect.minY, width: rect.width, height: rect.height - tailHeight)
        
        path.move(to: CGPoint(x: bubbleRect.minX + r, y: bubbleRect.minY))
        path.addLine(to: CGPoint(x: bubbleRect.maxX - r, y: bubbleRect.minY))
        path.addArc(withCenter: CGPoint(x: bubbleRect.maxX - r, y: bubbleRect.minY + r), radius: r, startAngle: -CGFloat.pi/2, endAngle: 0, clockwise: true)
        path.addLine(to: CGPoint(x: bubbleRect.maxX, y: bubbleRect.maxY - r))
        path.addArc(withCenter: CGPoint(x: bubbleRect.maxX - r, y: bubbleRect.maxY - r), radius: r, startAngle: 0, endAngle: CGFloat.pi/2, clockwise: true)
        
        // Tail
        let tailX = bubbleRect.midX - tailWidth/2
        path.addLine(to: CGPoint(x: tailX + tailWidth, y: bubbleRect.maxY))
        path.addLine(to: CGPoint(x: tailX + tailWidth/2, y: bubbleRect.maxY + tailHeight))
        path.addLine(to: CGPoint(x: tailX, y: bubbleRect.maxY))
        
        path.addLine(to: CGPoint(x: bubbleRect.minX + r, y: bubbleRect.maxY))
        path.addArc(withCenter: CGPoint(x: bubbleRect.minX + r, y: bubbleRect.maxY - r), radius: r, startAngle: CGFloat.pi/2, endAngle: CGFloat.pi, clockwise: true)
        path.addLine(to: CGPoint(x: bubbleRect.minX, y: bubbleRect.minY + r))
        path.addArc(withCenter: CGPoint(x: bubbleRect.minX + r, y: bubbleRect.minY + r), radius: r, startAngle: CGFloat.pi, endAngle: -CGFloat.pi/2, clockwise: true)
        
        return path
    }
    
    private static func scaleToFit(path: UIBezierPath, in rect: CGRect) -> UIBezierPath {
        let bounds = path.bounds
        guard bounds.width > 0 && bounds.height > 0 else { return path }
        let scaleX = rect.width / bounds.width
        let scaleY = rect.height / bounds.height
        
        let scaleTransform = CGAffineTransform(scaleX: scaleX, y: scaleY)
        path.apply(scaleTransform)
        
        let newBounds = path.bounds
        let translation = CGAffineTransform(translationX: rect.midX - newBounds.midX, y: rect.midY - newBounds.midY)
        path.apply(translation)
        
        return path
    }
    
    static func customShape(type: Int, in rect: CGRect) -> UIBezierPath {
        switch type {
        case 3: return star(in: rect)
        case 4: return triangle(in: rect)
        case 5: return pentagon(in: rect)
        case 6: return hexagon(in: rect)
        case 7: return speechBubble(in: rect)
        default: return UIBezierPath(roundedRect: rect, cornerRadius: 8)
        }
    }
}
