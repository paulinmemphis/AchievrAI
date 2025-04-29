//
//  StudentFeedbackGenerator 2.swift
//  MetacognitiveJournal
//
//  Created by Paul Thomas on 4/19/25.
//

// File: StudentFeedbackGenerator.swift
import Foundation
import Combine

/// Generates feedback messages for students based on their journal entries.
class StudentFeedbackGenerator: ObservableObject {
    @Published var feedback: String = ""
    private let securityManager = APISecurityManager.shared
    private let endpoint = URL(string: "https://api.openai.com/v1/chat/completions")!

    /// Generates feedback using an AI model.
    func generateFeedback(for entry: JournalEntry) {
        // Build the reflection text
        let text = entry.reflectionPrompts.compactMap { prompt in
            // Safely unwrap response or selectedOption
            if let response = prompt.response, !response.isEmpty {
                return response
            } else if let option = prompt.selectedOption, !option.isEmpty {
                return option
            } else {
                return nil
            }
        }.joined(separator: "\n")

        guard !text.isEmpty else {
            self.feedback = "No reflections available to generate feedback."
            return
        }

        // Compose AI prompt
        let aiPrompt = "Provide positive and constructive feedback for the following student reflections:\n" + text

        // Prepare request payload
        let payload: [String: Any] = [
            "model": "gpt-3.5-turbo",
            "messages": [["role": "user", "content": aiPrompt]],
            "temperature": 0.7
        ]

        // Retrieve API key securely
        guard let apiKey = securityManager.getAPIKeyForService("OpenAI") else {
            DispatchQueue.main.async {
                let error = AppError.internalError(message: "OpenAI API Key not found. Please configure it.")
                ErrorHandler.shared.handle(error)
                self.feedback = "Error: API Key missing."
            }
            return
        }

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: payload)

        URLSession.shared.dataTask(with: request) { data, _, error in
            if let error = error {
                DispatchQueue.main.async {
                    ErrorHandler.shared.handle(error, type: { msg in AppError.internalError(message: "Network error: \(msg)") })
                    self.feedback = "Error: \(error.localizedDescription)"
                }
                return
            }
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let choices = json["choices"] as? [[String: Any]],
                  let messageDict = choices.first?["message"] as? [String: Any],
                  let content = messageDict["content"] as? String else {
                DispatchQueue.main.async {
                    let parseError = NSError(domain: "AIResponse", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to parse AI response."])
                    ErrorHandler.shared.handle(parseError, type: { msg in AppError.internalError(message: "Network error: \(msg)") })
                    self.feedback = "Failed to parse AI response."
                }
                return
            }
            DispatchQueue.main.async {
                // Trim and assign
                self.feedback = content.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }.resume()
    }
}
