import Foundation

/// オフライン漢字変換エンジン (SKK辞書ベース)
class KanjiConverter {
    
    static let shared = KanjiConverter()
    
    /// 辞書: [ひらがな読み: [変換候補]]
    private var dictionary: [String: [String]] = [:]
    
    /// 辞書が読み込み済みかどうか
    private(set) var isLoaded: Bool = false
    
    private init() {
        loadDictionary()
    }
    
    // MARK: - Dictionary Loading
    
    private func loadDictionary() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let url = Bundle.main.url(forResource: "dictionary", withExtension: "json") else {
                print("KanjiConverter: dictionary.json not found in bundle")
                return
            }
            
            do {
                let data = try Data(contentsOf: url)
                let dict = try JSONDecoder().decode([String: [String]].self, from: data)
                DispatchQueue.main.async {
                    self?.dictionary = dict
                    self?.isLoaded = true
                    print("KanjiConverter: loaded \(dict.count) entries")
                }
            } catch {
                print("KanjiConverter: failed to load dictionary: \(error)")
            }
        }
    }
    
    // MARK: - Conversion
    
    /// ひらがな文字列から変換候補を返す
    /// - Parameter reading: ひらがなの読み
    /// - Returns: 変換候補の配列 (最大10件)。見つからなければ空配列
    func candidates(for reading: String) -> [String] {
        guard isLoaded, !reading.isEmpty else { return [] }
        
        // 完全一致
        if let results = dictionary[reading] {
            return Array(results.prefix(10))
        }
        
        return []
    }
    
    /// ひらがな文字列を最長一致で分割して変換候補を生成する
    /// - Parameter text: ひらがなのテキスト
    /// - Returns: 変換候補のリスト (各セグメントの最初の候補を結合したもの + 個別候補)
    func convert(_ text: String) -> [String] {
        guard isLoaded, !text.isEmpty else { return [] }
        
        var results: [String] = []
        
        // 1. 全体一致
        if let fullMatch = dictionary[text] {
            results.append(contentsOf: fullMatch.prefix(5))
        }
        
        // 2. 最長一致で分割変換のバリエーションを追加
        let segments = segmentize(text)
        if segments.count > 1 {
            // セグメントごとの候補リストを取得
            let segmentCands: [[String]] = segments.map { seg in
                if let cands = dictionary[seg], !cands.isEmpty { return cands }
                return [seg]
            }
            
            // 全てトップ候補の結合
            let topCombined = segmentCands.map { $0[0] }.joined()
            if !results.contains(topCombined) { results.append(topCombined) }
            
            // 最初のセグメントだけ2〜5番目の候補を使ったバリエーション
            let firstCands = segmentCands[0]
            if firstCands.count > 1 {
                let restCombined = segmentCands.dropFirst().map { $0[0] }.joined()
                for i in 1..<min(firstCands.count, 10) {
                    let combined = firstCands[i] + restCombined
                    if !results.contains(combined) { results.append(combined) }
                }
            }
            
            // 2番目のセグメントだけ2〜5番目の候補を使ったバリエーション
            if segmentCands.count > 1 {
                let secondCands = segmentCands[1]
                if secondCands.count > 1 {
                    for i in 1..<min(secondCands.count, 5) {
                        var temp = segmentCands.map { $0[0] }
                        temp[1] = secondCands[i]
                        let combined = temp.joined()
                        if !results.contains(combined) { results.append(combined) }
                    }
                }
            }
        } else if segments.count == 1 {
            let seg = segments[0]
            if let cands = dictionary[seg] {
                for c in cands.prefix(10) {
                    if !results.contains(c) { results.append(c) }
                }
            }
        }
        
        // 3. カタカナ・半角カタカナを候補に追加
        let katakanaStr = text.toKatakana()
        let halfKatakanaStr = katakanaStr.toHalfWidth()
        
        if !results.contains(katakanaStr) {
            results.append(katakanaStr)
        }
        if !results.contains(halfKatakanaStr) {
            results.append(halfKatakanaStr)
        }
        
        // 4. ひらがなそのままも候補に
        if !results.contains(text) {
            results.append(text)
        }
        
        return results
    }
    
    // MARK: - Segmentation (最長一致法)
    
    /// ひらがなテキストを辞書の最長一致で分割する
    private func segmentize(_ text: String) -> [String] {
        let chars = Array(text)
        var segments: [String] = []
        var i = 0
        
        while i < chars.count {
            var bestLength = 1
            // 最大20文字まで先読み
            let maxLen = min(chars.count - i, 20)
            
            for len in stride(from: maxLen, through: 2, by: -1) {
                let substr = String(chars[i..<(i + len)])
                if dictionary[substr] != nil {
                    bestLength = len
                    break
                }
            }
            
            let segment = String(chars[i..<(i + bestLength)])
            segments.append(segment)
            i += bestLength
        }
        
        return segments
    }
}
