import UIKit
import CoreText

struct CustomFont {
    var fontName: String
    var displayName: String
    var fileURL: URL
}

class CustomFontManager {
    static let shared = CustomFontManager()
    
    private let fontsDirectory: URL? = {
        guard let groupURL = AppGroupHelper.shared.containerURL() else { return nil }
        let dir = groupURL.appendingPathComponent("Fonts", isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true, attributes: nil)
        }
        return dir
    }()
    
    private var displayNames: [String: String] {
        get {
            return AppGroupHelper.shared.userDefaults?.dictionary(forKey: "customFontDisplayNames") as? [String: String] ?? [:]
        }
        set {
            AppGroupHelper.shared.userDefaults?.set(newValue, forKey: "customFontDisplayNames")
            AppGroupHelper.shared.userDefaults?.synchronize()
        }
    }
    
    func registerAllCustomFonts() {
        guard let fontsDirectory = fontsDirectory else { return }
        guard let files = try? FileManager.default.contentsOfDirectory(at: fontsDirectory, includingPropertiesForKeys: nil) else { return }
        
        for fileURL in files where fileURL.pathExtension.lowercased() == "ttf" || fileURL.pathExtension.lowercased() == "otf" {
            var error: Unmanaged<CFError>?
            CTFontManagerRegisterFontsForURL(fileURL as CFURL, .process, &error)
        }
    }
    
    func importFont(from url: URL, completion: @escaping (String?, String?) -> Void) {
        guard let fontsDirectory = fontsDirectory else {
            completion(nil, "App Group directory not found")
            return
        }
        
        let destinationURL = fontsDirectory.appendingPathComponent(url.lastPathComponent)
        
        do {
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(at: destinationURL)
            }
            try FileManager.default.copyItem(at: url, to: destinationURL)
            
            var error: Unmanaged<CFError>?
            if CTFontManagerRegisterFontsForURL(destinationURL as CFURL, .process, &error) {
                // Get the actual font name
                if let descriptors = CTFontManagerCreateFontDescriptorsFromURL(destinationURL as CFURL) as? [CTFontDescriptor],
                   let descriptor = descriptors.first {
                    let fontName = CTFontDescriptorCopyAttribute(descriptor, kCTFontNameAttribute) as? String
                    
                    // Set default display name as the file name without extension
                    if let fontName = fontName {
                        var names = displayNames
                        if names[fontName] == nil {
                            names[fontName] = url.deletingPathExtension().lastPathComponent
                            displayNames = names
                        }
                    }
                    
                    completion(fontName, nil)
                } else {
                    completion(nil, "Could not read font name")
                }
            } else {
                let errStr = error?.takeRetainedValue().localizedDescription ?? "Unknown error"
                completion(nil, "Failed to register font: \(errStr)")
            }
        } catch {
            completion(nil, "Failed to copy file: \(error.localizedDescription)")
        }
    }
    
    func getCustomFonts() -> [CustomFont] {
        guard let fontsDirectory = fontsDirectory else { return [] }
        guard let files = try? FileManager.default.contentsOfDirectory(at: fontsDirectory, includingPropertiesForKeys: nil) else { return [] }
        
        var fonts: [CustomFont] = []
        let names = displayNames
        
        for fileURL in files {
            if let descriptors = CTFontManagerCreateFontDescriptorsFromURL(fileURL as CFURL) as? [CTFontDescriptor],
               let descriptor = descriptors.first,
               let fontName = CTFontDescriptorCopyAttribute(descriptor, kCTFontNameAttribute) as? String {
                
                let displayName = names[fontName] ?? fontName
                fonts.append(CustomFont(fontName: fontName, displayName: displayName, fileURL: fileURL))
            }
        }
        return fonts
    }
    
    func setDisplayName(_ displayName: String, forFont fontName: String) {
        var names = displayNames
        names[fontName] = displayName
        displayNames = names
    }
    
    func removeFont(_ font: CustomFont) {
        try? FileManager.default.removeItem(at: font.fileURL)
        var error: Unmanaged<CFError>?
        CTFontManagerUnregisterFontsForURL(font.fileURL as CFURL, .process, &error)
        
        var names = displayNames
        names.removeValue(forKey: font.fontName)
        displayNames = names
    }
}
