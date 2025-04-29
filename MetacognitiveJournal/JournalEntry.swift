// File: JournalEntry.swift
import Foundation

/// Represents a complete journal entry, including metacognitive reflections and optional audio.
///
/// Conforms to `Codable` for persistence, `Identifiable` for use in SwiftUI lists,
/// and `Hashable` for use in sets or dictionaries if needed.
struct JournalEntry: Identifiable, Codable, Hashable {
    /// Unique identifier for the journal entry.
    let id: UUID
    /// The name of the assignment associated with this journal entry.
    var assignmentName: String
    /// The date and time the entry was created or last modified.
    var date: Date
    /// The subject of the assignment associated with this journal entry.
    var subject: K12Subject
    /// The emotional state selected by the user for this entry.
    var emotionalState: EmotionalState
    /// The user's reflection on the assignment, including answers to prompts.
    var reflectionPrompts: [PromptResponse]
    /// Optional AI-generated summary or insights for the entry.
    var aiSummary: String?
    /// Optional tone used by AI (if any) for the entry.
    var aiTone: String?
    /// Optional URL pointing to an associated audio recording for voice entries.
    var audioURL: URL?
    /// Optional text generated from speech-to-text transcription of the audio recording.
    var transcription: String?

    // MARK: - CodingKeys
    private enum CodingKeys: String, CodingKey {
        case id, assignmentName, date, subject, emotionalState, reflectionPrompts,
             aiSummary, aiTone, audioURL, transcription
    }

    // MARK: - Initializers

    /// Memberwise Initializer
    init(
        id: UUID,
        assignmentName: String,
        date: Date,
        subject: K12Subject,
        emotionalState: EmotionalState,
        reflectionPrompts: [PromptResponse],
        aiSummary: String? = nil,
        aiTone: String? = nil,
        transcription: String? = nil,
        audioURL: URL? = nil
    ) {
        self.id = id
        self.assignmentName = assignmentName
        self.date = date
        self.subject = subject
        self.emotionalState = emotionalState
        self.reflectionPrompts = reflectionPrompts
        self.aiSummary = aiSummary
        self.aiTone = aiTone
        self.transcription = transcription
        self.audioURL = audioURL
    }

    /// Decoder Initializer (for Codable conformance)
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        assignmentName = try container.decode(String.self, forKey: .assignmentName)
        date = try container.decode(Date.self, forKey: .date)
        subject = try container.decode(K12Subject.self, forKey: .subject)
        emotionalState = try container.decode(EmotionalState.self, forKey: .emotionalState)
        reflectionPrompts = try container.decode([PromptResponse].self, forKey: .reflectionPrompts)
        aiSummary = try container.decodeIfPresent(String.self, forKey: .aiSummary)
        aiTone = try container.decodeIfPresent(String.self, forKey: .aiTone)
        audioURL = try container.decodeIfPresent(URL.self, forKey: .audioURL)
        transcription = try container.decodeIfPresent(String.self, forKey: .transcription)
    }

    // MARK: - Codable Conformance

    /// Encoder (for Codable conformance)
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(assignmentName, forKey: .assignmentName)
        try container.encode(date, forKey: .date)
        try container.encode(subject, forKey: .subject)
        try container.encode(self.emotionalState, forKey: .emotionalState)
        try container.encode(reflectionPrompts, forKey: .reflectionPrompts)
        try container.encodeIfPresent(aiSummary, forKey: .aiSummary)
        try container.encodeIfPresent(aiTone, forKey: .aiTone)
        try container.encodeIfPresent(audioURL, forKey: .audioURL)
        try container.encodeIfPresent(transcription, forKey: .transcription)
    }
}
