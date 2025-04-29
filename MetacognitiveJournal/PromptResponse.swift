// File: PromptResponse.swift
import Foundation

/// Represents a user response to a reflection prompt.
public struct PromptResponse: Identifiable, Codable, Hashable {
    public let id: UUID
    public let prompt: String
    public var options: [String]?           // Available options (if any)
    public var selectedOption: String?      // Chosen option (if any)
    public var response: String?            // Free-text response
    public var isFavorited: Bool?           // Optional favorite flag
    public var rating: Int?                 // Optional rating

    public init(
        id: UUID,
        prompt: String,
        options: [String]? = nil,
        selectedOption: String? = nil,
        response: String? = nil,
        isFavorited: Bool? = nil,
        rating: Int? = nil
    ) {
        self.id = id
        self.prompt = prompt
        self.options = options
        self.selectedOption = selectedOption
        self.response = response
        self.isFavorited = isFavorited
        self.rating = rating
    }
}
