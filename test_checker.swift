import Foundation
import UIKit

let checker = UITextChecker()
let text = "きょうはいいてんきですね"
let range = NSRange(location: 0, length: text.utf16.count)
if let completions = checker.completions(forPartialWordRange: range, in: text, language: "ja_JP") {
    print("Completions:", completions)
} else {
    print("No completions")
}
if let guesses = checker.guesses(forWordRange: range, in: text, language: "ja_JP") {
    print("Guesses:", guesses)
} else {
    print("No guesses")
}
