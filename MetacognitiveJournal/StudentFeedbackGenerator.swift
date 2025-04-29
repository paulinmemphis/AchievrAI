//
//  StudentFeedbackGenerator.swift
//  MetacognitiveJournal
//
//  Created by Paul Thomas on 4/19/25.
//

import Foundation
import Combine

/// Generates personalized feedback messages for students based on their journal entries.
///
/// This class uses an AI model to analyze student reflections and generate constructive,
/// encouraging feedback that promotes metacognitive development. The feedback is designed
/// to help students identify patterns in their thinking, recognize their strengths, and
/// develop strategies for improvement.
///
/// - Important: Requires a valid OpenAI API key to be configured in the `APISecurityManager`.
///
/// ## Example Usage
/// ```swift
/// let feedbackGenerator = StudentFeedbackGenerator()
/// feedbackGenerator.generateFeedback(for: journalEntry)
/// // Later, access the feedback
/// let feedback = feedbackGenerator.feedback
/// ```
class StudentFeedbackGenerator: ObservableObject {
    /// The generated feedback text that will be displayed to the student.
    /// This property is published and will trigger UI updates when changed.
    @Published var feedback: String = ""
    
    /// Security manager used to securely retrieve API keys.
    private let securityManager = APISecurityManager.shared
    
    /// The OpenAI API endpoint for chat completions.
    private let endpoint = URL(string: "https://api.openai.com/v1/chat/completions")!

    /// Generates personalized feedback for a journal entry using an AI model.
    ///
    /// This method extracts the reflection text from the journal entry, constructs an appropriate
    /// prompt for the AI model, and sends a request to the OpenAI API. The resulting feedback
    /// is then processed and made available through the `feedback` published property.
    ///
    /// - Parameter entry: The journal entry containing reflections to analyze.
    /// - Important: This method requires internet connectivity and a valid API key.
    /// - Note: If the entry contains no reflections, a default message will be set.
    func generateFeedback(for entry: JournalEntry) {
        // Build the reflection text by combining all non-empty responses and selected options
        let text = entry.reflectionPrompts.compactMap { prompt in
            // Safely unwrap response or selectedOption, prioritizing free-text responses
            if let response = prompt.response, !response.isEmpty {
                return response
            } else if let option = prompt.selectedOption, !option.isEmpty {
                return option
            } else {
                return nil
            }
        }.joined(separator: "\n")

        // Ensure we have reflection text to analyze
        guard !text.isEmpty else {
            self.feedback = "No reflections available to generate feedback."
            return
        }

        // Compose AI prompt with specific instructions for constructive feedback
        let aiPrompt = "Provide positive and constructive feedback for the following student reflections. Focus on metacognitive development, highlight strengths, and suggest one area for growth. Keep the tone encouraging and supportive:\n" + text

        // Prepare request payload with model configuration
        let payload: [String: Any] = [
            "model": "gpt-3.5-turbo",      // Use GPT-3.5 Turbo for efficient, cost-effective responses
            "messages": [["role": "user", "content": aiPrompt]],
            "temperature": 0.7,            // Balance between creativity and consistency
            "max_tokens": 300              // Limit response length for concise feedback
        ]

        // Retrieve API key securely from the security manager
        guard let apiKey = securityManager.getAPIKeyForService("OpenAI") else {
            DispatchQueue.main.async {
                // Create and handle a specific error for missing API key
                let error = JournalAppError.internalError(message: "OpenAI API Key not found. Please configure it.")
                ErrorHandler.shared.handle(error)
                self.feedback = "Error: API Key missing."
            }
            return
        }

        // Configure the HTTP request with proper headers and authentication
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30  // Set a reasonable timeout
        
        // Serialize the payload to JSON
        request.httpBody = try? JSONSerialization.data(withJSONObject: payload)

        // Execute the network request asynchronously
        URLSession.shared.dataTask(with: request) { data, response, error in
            // Handle network errors
            if let error = error {
                DispatchQueue.main.async {
                    // Create a specific error type and handle it through the error handler
                    ErrorHandler.shared.handle(error, type: { msg in 
                        JournalAppError.internalError(message: "Network error: \(msg)")
                    })
                    self.feedback = "Error: \(error.localizedDescription)"
                }
                return
            }
            
            // Check for HTTP status code
            if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
                DispatchQueue.main.async {
                    let statusError = NSError(domain: "AIResponse", code: httpResponse.statusCode, 
                                              userInfo: [NSLocalizedDescriptionKey: "Server returned status code \(httpResponse.statusCode)"])
                    ErrorHandler.shared.handle(statusError, type: { msg in 
                        JournalAppError.internalError(message: "API error: \(msg)")
                    })
                    self.feedback = "Error: Server returned status \(httpResponse.statusCode)"
                }
                return
            }
            
            // Parse the JSON response
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let choices = json["choices"] as? [[String: Any]],
                  let messageDict = choices.first?["message"] as? [String: Any],
                  let content = messageDict["content"] as? String else {
                DispatchQueue.main.async {
                    // Create and handle a parsing error
                    let parseError = NSError(domain: "AIResponse", code: 0, 
                                            userInfo: [NSLocalizedDescriptionKey: "Failed to parse AI response."])
                    ErrorHandler.shared.handle(parseError, type: { msg in 
                        JournalAppError.internalError(message: "Parsing error: \(msg)")
                    })
                    self.feedback = "Failed to parse AI response."
                }
                return
            }
            
            // Update the feedback on the main thread
            DispatchQueue.main.async {
                // Trim whitespace and newlines from the response
                self.feedback = content.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }.resume()
    }
}
