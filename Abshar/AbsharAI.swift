//
//  ContentView.swift
//  Abshar
//
//  Created by Danyah ALbarqawi on 11/12/2025.
//

import Foundation
internal import Combine

class AbsherAI: ObservableObject {
    
    private let apiKey = "YOUR-NEW-API-KEY-HERE"  // ← Put your key
    
    func processCommand(_ userSpeech: String) async throws -> AIResponse {
        
        let url = URL(string: "https://integrate.api.nvidia.com/v1/chat/completions")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "model": "meta/llama-3.1-8b-instruct",
            "messages": [
                [
                    "role": "system",
                    "content": """
                    You are Absher voice assistant. Respond ONLY with valid JSON.
                    
                    Screens: identity, passport, driving, visa, traffic, civil, home
                    
                    Format: {"action":"navigate","screen":"identity","message":"سأنقلك لتجديد الهوية","requiresConfirmation":false}
                    
                    Rules:
                    - هوية/الهوية → identity
                    - جواز → passport  
                    - رخصة/قيادة → driving
                    - تأشيرة/فيزا → visa
                    - مرور → traffic
                    - أحوال → civil
                    - رئيسية/رجع → home
                    - Questions → action:"answer", screen:""
                    
                    JSON ONLY. Arabic message. No extra text.
                    """
                ],
                [
                    "role": "user",
                    "content": userSpeech
                ]
            ],
            "max_tokens": 150,
            "temperature": 0.1
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        
        // Parse API response
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            
            // API failed - use keyword detection
            return detectIntentFromText(userSpeech)
        }
        
        return parseAIResponse(content, originalInput: userSpeech)
    }
    
    private func parseAIResponse(_ content: String, originalInput: String) -> AIResponse {
        
        var jsonString = content
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Extract JSON
        if let startIndex = jsonString.firstIndex(of: "{"),
           let endIndex = jsonString.lastIndex(of: "}") {
            jsonString = String(jsonString[startIndex...endIndex])
        }
        
        // Parse JSON
        if let data = jsonString.data(using: .utf8),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            
            let actionString = json["action"] as? String ?? "answer"
            let action: AIAction = actionString == "navigate" ? .navigate : .answer
            let screen = json["screen"] as? String
            let message = json["message"] as? String ?? "كيف أقدر أساعدك؟"
            let requiresConfirmation = json["requiresConfirmation"] as? Bool ?? false
            
            return AIResponse(action: action, screen: screen, message: message, requiresConfirmation: requiresConfirmation)
        }
        
        // Fallback to keyword detection
        return detectIntentFromText(originalInput)
    }
    
    private func detectIntentFromText(_ text: String) -> AIResponse {
        
        let input = text.lowercased()
        
        if input.contains("هوية") || input.contains("الهوية") {
            return AIResponse(action: .navigate, screen: "identity", message: "سأنقلك لخدمة تجديد الهوية", requiresConfirmation: false)
        }
        
        if input.contains("جواز") || input.contains("الجواز") {
            return AIResponse(action: .navigate, screen: "passport", message: "سأنقلك لخدمات الجواز", requiresConfirmation: false)
        }
        
        if input.contains("رخصة") || input.contains("قيادة") {
            return AIResponse(action: .navigate, screen: "driving", message: "سأنقلك لخدمات رخصة القيادة", requiresConfirmation: false)
        }
        
        if input.contains("تأشير") || input.contains("فيزا") {
            return AIResponse(action: .navigate, screen: "visa", message: "سأنقلك لخدمات التأشيرات", requiresConfirmation: false)
        }
        
        if input.contains("مرور") || input.contains("المرور") {
            return AIResponse(action: .navigate, screen: "traffic", message: "سأنقلك لخدمات المرور", requiresConfirmation: false)
        }
        
        if input.contains("أحوال") || input.contains("مدنية") {
            return AIResponse(action: .navigate, screen: "civil", message: "سأنقلك للأحوال المدنية", requiresConfirmation: false)
        }
        
        if input.contains("رئيسية") || input.contains("رجع") || input.contains("بيت") {
            return AIResponse(action: .navigate, screen: "home", message: "سأرجعك للرئيسية", requiresConfirmation: false)
        }
        
        // Default response
        return AIResponse(action: .answer, screen: nil, message: "كيف أقدر أساعدك؟ قل مثلاً: أبي أجدد الهوية", requiresConfirmation: false)
    }
}

// MARK: - Models

enum AIAction {
    case navigate
    case answer
    case confirm
}

struct AIResponse {
    let action: AIAction
    let screen: String?
    let message: String
    let requiresConfirmation: Bool
}
