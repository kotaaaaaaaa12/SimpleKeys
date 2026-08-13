import Foundation

/// ローマ字 → ひらがな変換エンジン
class RomajiConverter {
    
    // MARK: - Properties
    
    /// 変換バッファ（入力中のローマ字を溜める）
    private(set) var buffer: String = ""
    
    /// 変換済みのひらがな列
    private(set) var convertedText: String = ""
    
    // MARK: - Romaji → Kana Table
    
    private static let romajiTable: [(romaji: String, kana: String)] = [
        // 撥音・特殊
        ("nn", "ん"), ("n'", "ん"), ("xn", "ん"),
        
        // 拗音 (きゃ、しゃ、ちゃ、にゃ、ひゃ、みゃ、りゃ etc.)
        ("kya", "きゃ"), ("kyi", "きぃ"), ("kyu", "きゅ"), ("kye", "きぇ"), ("kyo", "きょ"),
        ("sha", "しゃ"), ("shi", "し"),   ("shu", "しゅ"), ("she", "しぇ"), ("sho", "しょ"),
        ("sya", "しゃ"), ("syi", "しぃ"), ("syu", "しゅ"), ("sye", "しぇ"), ("syo", "しょ"),
        ("cha", "ちゃ"), ("chi", "ち"),   ("chu", "ちゅ"), ("che", "ちぇ"), ("cho", "ちょ"),
        ("tya", "ちゃ"), ("tyi", "ちぃ"), ("tyu", "ちゅ"), ("tye", "ちぇ"), ("tyo", "ちょ"),
        ("cya", "ちゃ"), ("cyi", "ちぃ"), ("cyu", "ちゅ"), ("cye", "ちぇ"), ("cyo", "ちょ"),
        ("nya", "にゃ"), ("nyi", "にぃ"), ("nyu", "にゅ"), ("nye", "にぇ"), ("nyo", "にょ"),
        ("hya", "ひゃ"), ("hyi", "ひぃ"), ("hyu", "ひゅ"), ("hye", "ひぇ"), ("hyo", "ひょ"),
        ("mya", "みゃ"), ("myi", "みぃ"), ("myu", "みゅ"), ("mye", "みぇ"), ("myo", "みょ"),
        ("rya", "りゃ"), ("ryi", "りぃ"), ("ryu", "りゅ"), ("rye", "りぇ"), ("ryo", "りょ"),
        ("gya", "ぎゃ"), ("gyi", "ぎぃ"), ("gyu", "ぎゅ"), ("gye", "ぎぇ"), ("gyo", "ぎょ"),
        ("ja",  "じゃ"), ("ji",  "じ"),   ("ju",  "じゅ"), ("je",  "じぇ"), ("jo",  "じょ"),
        ("jya", "じゃ"), ("jyi", "じぃ"), ("jyu", "じゅ"), ("jye", "じぇ"), ("jyo", "じょ"),
        ("zya", "じゃ"), ("zyi", "じぃ"), ("zyu", "じゅ"), ("zye", "じぇ"), ("zyo", "じょ"),
        ("dya", "ぢゃ"), ("dyi", "ぢぃ"), ("dyu", "ぢゅ"), ("dye", "ぢぇ"), ("dyo", "ぢょ"),
        ("bya", "びゃ"), ("byi", "びぃ"), ("byu", "びゅ"), ("bye", "びぇ"), ("byo", "びょ"),
        ("pya", "ぴゃ"), ("pyi", "ぴぃ"), ("pyu", "ぴゅ"), ("pye", "ぴぇ"), ("pyo", "ぴょ"),
        
        // ふぁ行
        ("fa", "ふぁ"), ("fi", "ふぃ"), ("fu", "ふ"), ("fe", "ふぇ"), ("fo", "ふぉ"),
        ("fya", "ふゃ"), ("fyi", "ふぃ"), ("fyu", "ふゅ"), ("fye", "ふぇ"), ("fyo", "ふょ"),
        
        // ゔぁ行
        ("va", "ゔぁ"), ("vi", "ゔぃ"), ("vu", "ゔ"), ("ve", "ゔぇ"), ("vo", "ゔぉ"),
        ("vya", "ゔゃ"), ("vyi", "ゔぃ"), ("vyu", "ゔゅ"), ("vye", "ゔぇ"), ("vyo", "ゔょ"),
        
        // くぁ行 (qa, kwa, qwa)
        ("qa", "くぁ"), ("qi", "くぃ"), ("qu", "く"), ("qe", "くぇ"), ("qo", "くぉ"),
        ("kwa", "くぁ"), ("kwi", "くぃ"), ("kwu", "くぅ"), ("kwe", "くぇ"), ("kwo", "くぉ"),
        ("qwa", "くぁ"), ("qwi", "くぃ"), ("qwu", "くぅ"), ("qwe", "くぇ"), ("qwo", "くぉ"),
        ("qya", "くゃ"), ("qyu", "くゅ"), ("qyo", "くょ"),
        
        // ぐぁ行 (gwa)
        ("gwa", "ぐぁ"), ("gwi", "ぐぃ"), ("gwu", "ぐぅ"), ("gwe", "ぐぇ"), ("gwo", "ぐぉ"),
        
        // うぁ行 (wha)
        ("wha", "うぁ"), ("whi", "うぃ"), ("whu", "う"), ("whe", "うぇ"), ("who", "うぉ"),
        
        // つぁ行
        ("tsa", "つぁ"), ("tsi", "つぃ"), ("tsu", "つ"), ("tse", "つぇ"), ("tso", "つぉ"),
        
        // てぃ、でぃ etc.
        ("tha", "てゃ"), ("thi", "てぃ"), ("thu", "てゅ"), ("the", "てぇ"), ("tho", "てょ"),
        ("dha", "でゃ"), ("dhi", "でぃ"), ("dhu", "でゅ"), ("dhe", "でぇ"), ("dho", "でょ"),
        
        // c の代替
        ("ca", "か"), ("ci", "し"), ("cu", "く"), ("ce", "せ"), ("co", "こ"),
        
        // 基本 か行
        ("ka", "か"), ("ki", "き"), ("ku", "く"), ("ke", "け"), ("ko", "こ"),
        // 基本 さ行
        ("sa", "さ"), ("si", "し"), ("su", "す"), ("se", "せ"), ("so", "そ"),
        // 基本 た行
        ("ta", "た"), ("ti", "ち"), ("tu", "つ"), ("te", "て"), ("to", "と"),
        // 基本 な行
        ("na", "な"), ("ni", "に"), ("nu", "ぬ"), ("ne", "ね"), ("no", "の"),
        // 基本 は行
        ("ha", "は"), ("hi", "ひ"), ("hu", "ふ"), ("he", "へ"), ("ho", "ほ"),
        // 基本 ま行
        ("ma", "ま"), ("mi", "み"), ("mu", "む"), ("me", "め"), ("mo", "も"),
        // 基本 や行
        ("ya", "や"), ("yi", "い"), ("yu", "ゆ"), ("ye", "いぇ"), ("yo", "よ"),
        // 基本 ら行
        ("ra", "ら"), ("ri", "り"), ("ru", "る"), ("re", "れ"), ("ro", "ろ"),
        // 基本 わ行
        ("wa", "わ"), ("wi", "うぃ"), ("wu", "う"), ("we", "うぇ"), ("wo", "を"),
        ("wyi", "ゐ"), ("wye", "ゑ"),
        
        // 濁音 が行
        ("ga", "が"), ("gi", "ぎ"), ("gu", "ぐ"), ("ge", "げ"), ("go", "ご"),
        // 濁音 ざ行
        ("za", "ざ"), ("zi", "じ"), ("zu", "ず"), ("ze", "ぜ"), ("zo", "ぞ"),
        // 濁音 だ行
        ("da", "だ"), ("di", "ぢ"), ("du", "づ"), ("de", "で"), ("do", "ど"),
        // 濁音 ば行
        ("ba", "ば"), ("bi", "び"), ("bu", "ぶ"), ("be", "べ"), ("bo", "ぼ"),
        // 半濁音 ぱ行
        ("pa", "ぱ"), ("pi", "ぴ"), ("pu", "ぷ"), ("pe", "ぺ"), ("po", "ぽ"),
        
        // 母音
        ("a", "あ"), ("i", "い"), ("u", "う"), ("e", "え"), ("o", "お"),
        
        // 小文字
        ("xa", "ぁ"), ("xi", "ぃ"), ("xu", "ぅ"), ("xe", "ぇ"), ("xo", "ぉ"),
        ("xya", "ゃ"), ("xyu", "ゅ"), ("xyo", "ょ"),
        ("xtu", "っ"), ("xtsu", "っ"),
        ("xwa", "ゎ"), ("xka", "ヵ"), ("xke", "ヶ"),
        ("la", "ぁ"), ("li", "ぃ"), ("lu", "ぅ"), ("le", "ぇ"), ("lo", "ぉ"),
        ("lya", "ゃ"), ("lyu", "ゅ"), ("lyo", "ょ"),
        ("ltu", "っ"), ("ltsu", "っ"),
        ("lwa", "ゎ"), ("lka", "ヵ"), ("lke", "ヶ"),
        
        // 記号
        ("-", "ー"),
    ]
    
    /// 子音のみ（ローマ字の先頭として有効な文字）
    private static let validPrefixes: Set<String> = {
        var prefixes = Set<String>()
        for entry in romajiTable {
            let romaji = entry.romaji
            for i in 1..<romaji.count {
                let prefix = String(romaji.prefix(i))
                prefixes.insert(prefix)
            }
        }
        return prefixes
    }()
    
    // MARK: - Public Methods
    
    /// ローマ字1文字を入力してバッファを更新する
    /// - Returns: 変換結果（バッファの現在状態）
    @discardableResult
    func input(_ char: Character) -> ConversionResult {
        let c = String(char).lowercased()
        buffer += c
        
        return processBuffer()
    }
    
    /// バッファの最後の1文字を削除
    func deleteBackward() -> ConversionResult {
        if !buffer.isEmpty {
            buffer.removeLast()
        } else if !convertedText.isEmpty {
            convertedText.removeLast()
        }
        return ConversionResult(
            converted: convertedText,
            pending: buffer,
            justConverted: nil
        )
    }
    
    /// 全バッファをクリア
    func clear() {
        buffer = ""
        convertedText = ""
    }
    
    /// 現在のバッファを確定してリセット
    func commit() -> String {
        let result = convertedText + buffer
        clear()
        return result
    }
    
    /// カナを直接入力する（フリック用）
    func inputKana(_ text: String) {
        convertedText += text
    }
    
    /// 最後のカナを置換する（フリックの濁点・半濁点用）
    func replaceLastKana(with text: String) {
        if !buffer.isEmpty {
            buffer.removeLast()
            buffer += text
        } else if !convertedText.isEmpty {
            convertedText.removeLast()
            convertedText += text
        }
    }
    
    var hasPendingInput: Bool {
        return !buffer.isEmpty || !convertedText.isEmpty
    }
    
    /// 現在の表示テキスト（変換済み + バッファ）
    var displayText: String {
        return convertedText + buffer
    }
    
    // MARK: - Private Methods
    
    private func processBuffer() -> ConversionResult {
        var justConverted: String? = nil
        
        // 促音チェック: 同じ子音が2つ続く場合 (kk→っk, tt→っt, etc.)
        // ただし "nn" は「ん」なので除外
        if buffer.count >= 2 {
            let chars = Array(buffer)
            let first = chars[0]
            let second = chars[1]
            if first == second && first != "n" && first != "a" && first != "i" && first != "u" && first != "e" && first != "o" {
                convertedText += "っ"
                justConverted = "っ"
                buffer = String(buffer.dropFirst())
                // 残りのバッファを再処理
                let subResult = processBuffer()
                let combined = (justConverted ?? "") + (subResult.justConverted ?? "")
                return ConversionResult(
                    converted: subResult.converted,
                    pending: subResult.pending,
                    justConverted: combined.isEmpty ? nil : combined
                )
            }
        }
        
        // テーブルから完全一致を探す
        for entry in RomajiConverter.romajiTable {
            if buffer == entry.romaji {
                convertedText += entry.kana
                justConverted = entry.kana
                buffer = ""
                return ConversionResult(
                    converted: convertedText,
                    pending: buffer,
                    justConverted: justConverted
                )
            }
        }
        
        // 「n」の特殊処理: nの後に母音でもyでもnでも無い子音が来たら「ん」に変換
        if buffer.count >= 2 && buffer.hasPrefix("n") {
            let secondChar = buffer[buffer.index(after: buffer.startIndex)]
            let vowels: Set<Character> = ["a", "i", "u", "e", "o", "y", "n"]
            if !vowels.contains(secondChar) {
                convertedText += "ん"
                justConverted = "ん"
                buffer = String(buffer.dropFirst())
                let subResult = processBuffer()
                let combined = (justConverted ?? "") + (subResult.justConverted ?? "")
                return ConversionResult(
                    converted: subResult.converted,
                    pending: subResult.pending,
                    justConverted: combined.isEmpty ? nil : combined
                )
            }
        }
        
        // バッファがどのローマ字のプレフィックスにもならない場合、先頭を捨てる
        if !buffer.isEmpty && !RomajiConverter.validPrefixes.contains(buffer) && !RomajiConverter.romajiTable.contains(where: { $0.romaji == buffer }) {
            // バッファの先頭から1文字ずつ試して有効なプレフィックスを見つける
            let first = String(buffer.prefix(1))
            // 単独の文字がテーブルにあるか確認
            if let entry = RomajiConverter.romajiTable.first(where: { $0.romaji == first }) {
                convertedText += entry.kana
                justConverted = entry.kana
                buffer = String(buffer.dropFirst())
            } else {
                // 変換不可能な文字はそのまま出力
                convertedText += first
                justConverted = first
                buffer = String(buffer.dropFirst())
            }
            
            if !buffer.isEmpty {
                let subResult = processBuffer()
                let combined = (justConverted ?? "") + (subResult.justConverted ?? "")
                return ConversionResult(
                    converted: subResult.converted,
                    pending: subResult.pending,
                    justConverted: combined.isEmpty ? nil : combined
                )
            }
        }
        
        return ConversionResult(
            converted: convertedText,
            pending: buffer,
            justConverted: justConverted
        )
    }
}

// MARK: - ConversionResult

struct ConversionResult {
    /// 変換済みの全テキスト
    let converted: String
    /// まだバッファにあるローマ字
    let pending: String
    /// 今回新たに変換されたかな（nil = 変換なし）
    let justConverted: String?
}
