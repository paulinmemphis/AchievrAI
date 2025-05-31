// File: MetacognitiveAnalyzer.swift
import Foundation
import Combine

/// Analyzes journal entries using real AI integration (OpenAI API).
class MetacognitiveAnalyzer: ObservableObject {
    // MARK: - Properties
    
    // OpenAI API configuration
    private let apiKey: String
    private let baseURL = URL(string: "https://api.openai.com/v1/chat/completions")!
    private let model = "gpt-3.5-turbo"
    private let session = URLSession.shared
    private let decoder = JSONDecoder()
    
    // Analytics manager for tracking analysis events
    private let analyticsManager = AnalyticsManager.shared

    init(apiKey: String = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] ?? "") {
        self.apiKey = apiKey
    }

    // MARK: - Reflection Prompts
    let prompts: [String] = [
        "What was the most challenging part of this assignment?",
        "What strategy did you use to overcome challenges?",
        "What did you learn from completing this assignment?",
        "How will you apply what you learned next time?"
    ]

    // MARK: - Tone Analysis
    /// Analyzes the tone of a journal entry and returns a sentiment score between -1.0 (negative) and 1.0 (positive)
    /// - Parameter entry: The journal entry to analyze
    /// - Returns: A sentiment score between -1.0 and 1.0
    func analyzeTone(entry: JournalEntry) async throws -> Double {
        // Extract text from the entry
        let entryText = entry.reflectionPrompts.compactMap { $0.response }.joined(separator: "\n")
        
        guard !entryText.isEmpty else { return 0.0 }
        
        // Create system message instructing the AI
        let systemMessage = """
        You are an AI assistant that analyzes the emotional tone of journal entries.
        Analyze the text and return ONLY a number between -1.0 (extremely negative) and 1.0 (extremely positive)
        representing the overall emotional tone. Return only the number, no other text.
        """
        
        // Send the entry text as user message
        let userMessage = entryText
        
        // Send request to OpenAI API
        let response = try await sendChatRequest(messages: [
            ["role": "system", "content": systemMessage],
            ["role": "user", "content": userMessage]
        ])
        
        // Parse the response as a Double
        guard let sentiment = Double(response.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            throw NSError(domain: "MetacognitiveAnalyzer", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to parse sentiment score"])
        }
        
        // Ensure the sentiment is within the expected range
        let clampedSentiment = max(-1.0, min(1.0, sentiment))
        
        // Track the sentiment analysis in analytics
        analyticsManager.trackSentimentAnalysis(entryIds: [entry.id.uuidString], averageSentiment: clampedSentiment)
        
        return clampedSentiment
    }

    /// Analyzes the overall sentiment across multiple journal entries
    /// - Parameter entries: The journal entries to analyze
    /// - Returns: An average sentiment score between -1.0 and 1.0
    func analyzeOverallSentiment(entries: [JournalEntry]) async throws -> Double {
        guard !entries.isEmpty else { return 0.0 }
        
        var totalSentiment = 0.0
        
        for entry in entries {
            let sentiment = try await analyzeTone(entry: entry)
            totalSentiment += sentiment
        }
        
        let averageSentiment = totalSentiment / Double(entries.count)
        
        // Track the overall sentiment analysis in analytics
        analyticsManager.trackSentimentAnalysis(
            entryIds: entries.map { $0.id.uuidString },
            averageSentiment: averageSentiment
        )
        
        return averageSentiment
    }

    // MARK: - Reflection Depth Analysis
    /// Analyzes the reflection depth of a journal entry
    /// - Parameter entry: The journal entry to analyze
    /// - Returns: A reflection depth score between 0.0 (shallow) and 1.0 (deep)
    func analyzeReflectionDepth(entry: JournalEntry) async throws -> Double {
        // Extract text from the entry
        let entryText = entry.reflectionPrompts.compactMap { $0.response }.joined(separator: "\n")
        
        guard !entryText.isEmpty else { return 0.0 }
        
        // Create system message instructing the AI
        let systemMessage = """
        You are an AI assistant that analyzes the depth of reflection in journal entries.
        Analyze the text and return ONLY a number between 0.0 (shallow, superficial reflection) and 1.0 (deep, insightful reflection)
        representing the depth of metacognitive reflection. Return only the number, no other text.
        
        Consider these factors when scoring:
        - Self-awareness and introspection
        - Analysis of thought processes
        - Connections between experiences and learning
        - Questioning of assumptions
        - Consideration of multiple perspectives
        - Identification of patterns in thinking or behavior
        """
        
        // Send the entry text as user message
        let userMessage = entryText
        
        // Send request to OpenAI API
        let response = try await sendChatRequest(messages: [
            ["role": "system", "content": systemMessage],
            ["role": "user", "content": userMessage]
        ])
        
        // Parse the response as a Double
        guard let depth = Double(response.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            throw NSError(domain: "MetacognitiveAnalyzer", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to parse reflection depth score"])
        }
        
        // Ensure the depth is within the expected range
        let clampedDepth = max(0.0, min(1.0, depth))
        
        // Track the reflection depth analysis in analytics
        analyticsManager.trackReflectionDepthAnalysis(entryIds: [entry.id.uuidString], averageDepth: clampedDepth)
        
        return clampedDepth
    }

    // MARK: - Topic Extraction
    /// Extracts topics from journal entries
    /// - Parameter entries: The journal entries to analyze
    /// - Returns: An array of topics with their frequency
    func extractTopics(from entries: [JournalEntry]) async throws -> [(topic: String, count: Int)] {
        guard !entries.isEmpty else { return [] }
        
        // Combine text from all prompts in each entry, handling optional responses
        let combinedText = entries.map { entry in
            entry.reflectionPrompts.compactMap { $0.response }.joined(separator: "\n")
        }.joined(separator: "\n\n")
        
        guard !combinedText.isEmpty else { return [] }
        
        // Create system message instructing the AI
        let systemMessage = """
        You are an AI assistant that extracts key topics from journal entries.
        Analyze the text and extract the most significant topics or themes.
        Return ONLY a JSON array of strings representing the topics. For example: ["learning", "challenges", "growth", "relationships"]
        Limit to 10-15 most significant topics. Exclude common stop words and focus on meaningful concepts.
        """
        
        // Send the combined text as user message
        let userMessage = combinedText
        
        // Send request to OpenAI API
        let response = try await sendChatRequest(messages: [
            ["role": "system", "content": systemMessage],
            ["role": "user", "content": userMessage]
        ])
        
        // Parse the response as a JSON array
        let responseString = response.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Handle potential formatting issues in the response
        var jsonString = responseString
        if !jsonString.hasPrefix("[") {
            // Try to find the JSON array in the response
            if let startIndex = jsonString.firstIndex(of: "["),
               let endIndex = jsonString.lastIndex(of: "]") {
                jsonString = String(jsonString[startIndex...endIndex])
            } else {
                throw NSError(domain: "MetacognitiveAnalyzer", code: 3, userInfo: [NSLocalizedDescriptionKey: "Failed to parse topics JSON"])
            }
        }
        
        // Parse the JSON array
        guard let jsonData = jsonString.data(using: .utf8),
              let topics = try? JSONDecoder().decode([String].self, from: jsonData) else {
            throw NSError(domain: "MetacognitiveAnalyzer", code: 3, userInfo: [NSLocalizedDescriptionKey: "Failed to parse topics JSON"])
        }
        
        // Count occurrences of each topic in the text
        var topicCounts: [(topic: String, count: Int)] = []
        
        for topic in topics {
            let lowercaseTopic = topic.lowercased()
            let lowercaseText = combinedText.lowercased()
            
            // Count occurrences (simple approach)
            let components = lowercaseText.components(separatedBy: lowercaseTopic)
            let count = components.count - 1
            
            topicCounts.append((topic: topic, count: max(1, count)))
        }
        
        // Sort by count (descending)
        let sortedTopics = topicCounts.sorted { $0.count > $1.count }
        
        // Track the topic extraction in analytics
        analyticsManager.trackTopicExtraction(
            entryIds: entries.map { $0.id.uuidString },
            topicCount: sortedTopics.count,
            topTopics: sortedTopics.prefix(5).map { $0.topic }
        )
        
        return sortedTopics
    }

    // MARK: - Network Request
    private func sendChatRequest(messages: [[String: Any]]) async throws -> String {
        var request = URLRequest(url: baseURL)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "model": model,
            "messages": messages,
            "temperature": 0.2 // Lower temperature for more deterministic topic extraction
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
