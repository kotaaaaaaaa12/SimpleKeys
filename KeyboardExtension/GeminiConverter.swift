import Foundation

class GeminiConverter {
    static let shared = GeminiConverter()
    private init() {}
    
    private var currentTask: URLSessionDataTask?
    
    func convert(text: String, apiKey: String, completion: @escaping ([String]) -> Void) {
        currentTask?.cancel()
        
        guard !text.isEmpty, !apiKey.isEmpty else {
            completion([])
            return
        }
        
        let urlString = "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=\(apiKey)"
        guard let url = URL(string: urlString) else {
            completion([])
            return
        }
        
        let prompt = """
        あなたは日本語のIME（かな漢字変換）エンジンです。
        以下の「ひらがな」を文脈に合った自然な漢字かな交じり文に変換し、変換候補を5つ、改行区切りで出力してください。
        余計な説明や記号は一切含めず、変換結果のテキストのみを返してください。
        
        入力: \(text)
        """
        
        let requestBody: [String: Any] = [
            "contents": [
                ["parts": [["text": prompt]]]
            ],
            "generationConfig": [
                "temperature": 0.2,
                "maxOutputTokens": 100
            ]
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: requestBody)
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                if (error as NSError).code == NSURLErrorCancelled { return }
                print("Gemini API Error: \(error.localizedDescription)")
                DispatchQueue.main.async { completion([]) }
                return
            }
            
            guard let data = data else {
                DispatchQueue.main.async { completion([]) }
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let candidatesArray = json["candidates"] as? [[String: Any]],
                   let firstCandidate = candidatesArray.first,
                   let content = firstCandidate["content"] as? [String: Any],
                   let parts = content["parts"] as? [[String: Any]],
                   let firstPart = parts.first,
                   let responseText = firstPart["text"] as? String {
                    
                    let lines = responseText.components(separatedBy: .newlines)
                        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                        .filter { !$0.isEmpty }
                    
                    DispatchQueue.main.async {
                        completion(lines)
                    }
                } else {
                    DispatchQueue.main.async { completion([]) }
                }
            } catch {
                print("Gemini API JSON Error: \(error)")
                DispatchQueue.main.async { completion([]) }
            }
        }
        
        currentTask = task
        task.resume()
    }
}
