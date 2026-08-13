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
