//
//  PromptPersonalizationManager.swift
//  MetacognitiveJournal
//
//  Created by Paul Thomas on 4/19/25.
//


// PromptPersonalizationManager.swift
// MetacognitiveJournal

import Foundation
import Combine

class PromptPersonalizationManager: ObservableObject {
    @Published private(set) var favoritePrompts: Set<String> = []
    @Published private(set) var skippedPrompts: Set<String> = []

    // Toggle favorite status
    func toggleFavorite(prompt: String) {
        if favoritePrompts.contains(prompt) {
            favoritePrompts.remove(prompt)
        } else {
            favoritePrompts.insert(prompt)
        }
    }

    // Check if a prompt is favorited
    func isFavorite(prompt: String) -> Bool {
        favoritePrompts.contains(prompt)
    }

    // Toggle skipped status
    func toggleSkipped(prompt: String) {
        if skippedPrompts.contains(prompt) {
            skippedPrompts.remove(prompt)
        } else {
            skippedPrompts.insert(prompt)
        }
    }

    // Check if a prompt is skipped
    func isSkipped(prompt: String) -> Bool {
        skippedPrompts.contains(prompt)
    }
}
