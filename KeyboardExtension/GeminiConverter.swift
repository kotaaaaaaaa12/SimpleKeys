import Foundation

class GeminiConverter {
    static let shared = GeminiConverter()
    private init() {}
    
    private var currentTask: URLSessionDataTask?
    
    func convert(text: String, apiKey: String, model: String = "gemini-2.0-flash", completion: @escaping ([String]) -> Void) {
        // Cancel previous request if any
        currentTask?.cancel()
        
        guard !text.isEmpty, !apiKey.isEmpty else {
            completion(["[AI] 無効なリクエスト"])
            return
        }
        
        let cleanApiKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanModel = model.trimmingCharacters(in: .whitespacesAndNewlines)
        let urlString = "https://generativelanguage.googleapis.com/v1beta/models/\(cleanModel):createInteraction?key=\(cleanApiKey)"
        guard let url = URL(string: urlString) else {
            completion(["[AI] URLエラー"])
            return
        }
        
        let prompt = """
        あなたは日本語のIME（かな漢字変換）エンジンです。
        以下の「ひらがな」を文脈に合った自然な漢字かな交じり文に変換し、変換候補を5つ、改行区切りで出力してください。
        余計な説明や記号は一切含めず、変換結果のテキストのみを返してください。
        
        入力: \(text)
        """
        
        let body: [String: Any] = [
            "model": "models/\(cleanModel)",
            "input": [
                "parts": [
                    ["text": prompt]
                ]
            ],
            "store": false
        ]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: body) else {
            completion(["[AI] エンコードエラー"])
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                if (error as NSError).code == NSURLErrorCancelled { return }
                print("Gemini API Error: \(error.localizedDescription)")
                DispatchQueue.main.async { completion(["[AI] 通信エラー: \((error as NSError).code)"]) }
                return
            }
            
            guard let data = data else {
                DispatchQueue.main.async { completion(["[AI] データなし"]) }
                return
            }
            
            // Check HTTP status code
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                var errMsg = "\(httpResponse.statusCode)"
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let errObj = json["error"] as? [String: Any],
                   let msg = errObj["message"] as? String {
                    errMsg = "\(httpResponse.statusCode) \(msg)"
                }
                DispatchQueue.main.async { completion(["[AI] エラー: \(errMsg)"]) }
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    var responseText = ""
                    // Interactions API response
                    if let steps = json["steps"] as? [[String: Any]],
                       let lastStep = steps.last,
                       let content = lastStep["content"] as? [[String: Any]],
                       let firstContent = content.first,
                       let parsedText = firstContent["text"] as? String {
                        responseText = parsedText
                    }
                    // Fallback to legacy generateContent response just in case
                    else if let candidates = json["candidates"] as? [[String: Any]],
                       let firstCandidate = candidates.first,
                       let content = firstCandidate["content"] as? [String: Any],
                       let parts = content["parts"] as? [[String: Any]],
                       let firstPart = parts.first,
                       let parsedText = firstPart["text"] as? String {
                        responseText = parsedText
                    }
                    
                    if !responseText.isEmpty {
                        let lines = responseText.components(separatedBy: .newlines)
                            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                            .filter { !$0.isEmpty }
                        DispatchQueue.main.async {
                            completion(lines)
                        }
                    } else {
                        DispatchQueue.main.async { completion(["[AI] パース失敗"]) }
                    }
                } else {
                    DispatchQueue.main.async { completion(["[AI] パース失敗"]) }
                }
            } catch {
                print("Gemini API JSON Error: \(error)")
                DispatchQueue.main.async { completion(["[AI] JSONエラー"]) }
            }
        }
        
        currentTask = task
        task.resume()
    }
}
