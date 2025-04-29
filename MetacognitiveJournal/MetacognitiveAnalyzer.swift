// File: MetacognitiveAnalyzer.swift
import Foundation
import Combine

/// Analyzes journal entries using real AI integration (OpenAI API).
class MetacognitiveAnalyzer: ObservableObject {
    // MARK: - Reflection Prompts
    let prompts: [String] = [
        "What was the most challenging part of this assignment?",
        "What strategy did you use to overcome challenges?",
        "What did you learn from completing this assignment?",
        "How will you apply what you learned next time?"
    ]

    // MARK: - OpenAI Configuration
    private let apiKey: String
    private let session = URLSession.shared
    private let decoder = JSONDecoder()
    private let baseURL = URL(string: "https://api.openai.com/v1/chat/completions")!

    init(apiKey: String = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] ?? "") {
        self.apiKey = apiKey
    }

    // MARK: - Tone Analysis
    /// Uses OpenAI to analyze the tone of the given text.
    func analyzeTone(for text: String) async throws -> String {
        let systemMessage = "You are a tone analyzer. Return a single-word tone from: Frustrated, Confident, Overwhelmed, Curious, Neutral."
        let userMessage = text
        let response = try await sendChatRequest(messages: [
            ["role": "system", "content": systemMessage],
            ["role": "user",   "content": userMessage]
        ])
        return response.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Insight Generation
    /// Uses OpenAI to generate insights based on prompt responses.
    func generateInsights(from responses: [PromptResponse]) async throws -> String {
        let promptsText = responses.map { "\($0.prompt): \($0.response ?? "")" }.joined(separator: "\n")
        let systemMessage = "You are a helpful assistant that produces concise insights based on user reflections."
        let userMessage = """
Here are the reflections:
\(promptsText)
Please provide a brief summary with key insights.
"""
        let insight = try await sendChatRequest(messages: [
            ["role": "system", "content": systemMessage],
            ["role": "user",   "content": userMessage]
        ])
        return insight
    }

    // MARK: - Network Request
    private func sendChatRequest(messages: [[String: String]]) async throws -> String {
        var request = URLRequest(url: baseURL)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "model": "gpt-3.5-turbo",
            "messages": messages,
            "temperature": 0.7
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: request)
        guard let httpResp = response as? HTTPURLResponse,
              200..<300 ~= httpResp.statusCode else {
            throw URLError(.badServerResponse)
        }

        let chatResponse = try decoder.decode(ChatResponse.self, from: data)
        return chatResponse.choices.first?.message.content ?? ""
    }
}

// MARK: - OpenAI Response Models
private struct ChatResponse: Codable {
    struct Choice: Codable {
        struct Message: Codable { let role: String, content: String }
        let message: Message
    }
    let choices: [Choice]
}
