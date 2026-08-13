import UIKit
import Foundation

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
    
    func loadImage(fileName: String) -> UIImage? {
        guard let url = containerURL()?.appendingPathComponent(fileName) else { return nil }
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
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
    var flickHighlightHex: String?     // Flick popup selected highlight color
    var navStyle: Int?                 // 0: Characters, 1: Arrows, 2: Hidden
    var navColorHex: String?           // Custom color for nav hints
    
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
