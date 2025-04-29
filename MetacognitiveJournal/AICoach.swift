
// AICoach.swift
import Foundation
import NaturalLanguage
import Combine

/// Provides AI-driven coaching prompts, summaries, and tone nudges based on journal entries.
class AICoach: ObservableObject {
    static let shared = AICoach()

    @Published var suggestedPrompt: String? = nil
    @Published var summary: String? = nil
    @Published var toneNudge: String? = nil

    private let openAIEndpoint = URL(string: "https://api.openai.com/v1/chat/completions")!
    private let apiKey = "sk-REPLACE_WITH_YOUR_API_KEY"

    /// Generates a single metacognitive prompt based on recent entries.
    func generatePrompt(from entries: [JournalEntry]) {
        let texts = entries.prefix(10).flatMap { entry in
            entry.reflectionPrompts.compactMap { prompt in
                let resp = (prompt.response?.isEmpty == false) ? prompt.response! : prompt.selectedOption
                return resp
            }
        }
        guard !texts.isEmpty else { return }
        let promptText = texts.joined(separator: "\n")
        let fullPrompt = "Based on the following reflections, generate one helpful, thought-provoking metacognitive journal question that encourages deeper reflection:\n" + promptText

        sendToOpenAI(prompt: fullPrompt) { [weak self] result in
            DispatchQueue.main.async {
                self?.suggestedPrompt = result
            }
        }
    }

    /// Summarizes a single journal entry.
    func summarize(entry: JournalEntry) {
        let texts = entry.reflectionPrompts.compactMap { prompt in
            let resp = (prompt.response?.isEmpty == false) ? prompt.response! : prompt.selectedOption
            return resp
        }
        guard !texts.isEmpty else { return }
        let promptText = texts.joined(separator: "\n")
        let summaryPrompt = "Summarize this student's reflection concisely in 1-2 sentences:\n" + promptText

        sendToOpenAI(prompt: summaryPrompt) { [weak self] result in
            DispatchQueue.main.async {
                self?.summary = result
            }
        }
    }

    /// Generates a positive nudge based on a journal entry.
    func generateToneNudge(entry: JournalEntry) {
        let texts = entry.reflectionPrompts.compactMap { prompt in
            let resp = (prompt.response?.isEmpty == false) ? prompt.response! : prompt.selectedOption
            return resp
        }
        guard !texts.isEmpty else { return }
        let promptText = texts.joined(separator: "\n")
        let nudgePrompt = "Based on this journal entry, provide a positive and encouraging nudge or tip to support the student's mindset:\n" + promptText

        sendToOpenAI(prompt: nudgePrompt) { [weak self] result in
            DispatchQueue.main.async {
                self?.toneNudge = result
            }
        }
    }

    // MARK: - Networking

    private func sendToOpenAI(prompt: String, completion: @escaping (String?) -> Void) {
        let requestData: [String: Any] = [
            "model": "gpt-4",
            "messages": [["role": "user", "content": prompt]],
            "temperature": 0.7
        ]

        var request = URLRequest(url: openAIEndpoint)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: requestData)

        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let choices = json["choices"] as? [[String: Any]],
                  let message = choices.first?["message"] as? [String: Any],
                  let content = message["content"] as? String
            else {
                completion(nil)
                return
            }
            completion(content.trimmingCharacters(in: .whitespacesAndNewlines))
        }.resume()
    }
}
