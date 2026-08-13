import Foundation
import UIKit

class EnglishConverter {
    static let shared = EnglishConverter()
    private let checker = UITextChecker()
    
    func candidates(for text: String) -> [String] {
        guard !text.isEmpty else { return [] }
        
        var results: [String] = []
        
        // 1. Original (half-width)
        results.append(text)
        
        // 2. Uppercase / Capitalized
        let lower = text.lowercased()
        let upper = text.uppercased()
        let cap = text.capitalized
        if upper != text { results.append(upper) }
        if cap != text && cap != upper { results.append(cap) }
        
        // 3. Full-width (Zenkaku)
        let fullWidth = text.applyingTransform(.fullwidthToHalfwidth, reverse: true) ?? text
        if fullWidth != text {
            results.append(fullWidth)
        }
        
        // 4. Completions via UITextChecker
        let range = NSRange(location: 0, length: text.utf16.count)
        if let completions = checker.completions(forPartialWordRange: range, in: text, language: "en_US") {
            results.append(contentsOf: completions.prefix(5))
        }
        
        // 5. Guesses (Spell check) via UITextChecker
        if let guesses = checker.guesses(forWordRange: range, in: text, language: "en_US") {
            results.append(contentsOf: guesses.prefix(5))
        }
        
        // Deduplicate
        var unique = [String]()
        for r in results {
            if !unique.contains(r) {
                unique.append(r)
            }
        }
        
        return unique
    }
}
