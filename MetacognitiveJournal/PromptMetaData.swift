//
//  PromptMetaData 2.swift
//  MetacognitiveJournal
//
//  Created by Paul Thomas on 4/19/25.
//


// PromptMetaDataStore.swift
// Handles local file-based persistence for user prompt metadata

import Foundation

struct PromptMetaData: Codable, Identifiable, Equatable {
    let id: UUID
    var promptText: String
    var rating: Int? // 1–5 star scale
    var isFavorite: Bool
    var isSkipped: Bool

    init(id: UUID = UUID(), promptText: String, rating: Int? = nil, isFavorite: Bool = false, isSkipped: Bool = false) {
        self.id = id
        self.promptText = promptText
        self.rating = rating
        self.isFavorite = isFavorite
        self.isSkipped = isSkipped
    }
}

extension FileManager {
    static var promptMetaDataURL: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return docs.appendingPathComponent("PromptMetaData.json")
    }
}

class PromptMetaDataStore: ObservableObject {
    @Published private(set) var metadata: [PromptMetaData] = []

    init() {
        metadata = load()
    }

    func load() -> [PromptMetaData] {
        guard FileManager.default.fileExists(atPath: FileManager.promptMetaDataURL.path),
              let data = try? Data(contentsOf: FileManager.promptMetaDataURL),
              let decoded = try? JSONDecoder().decode([PromptMetaData].self, from: data) else {
            return []
        }
        return decoded
    }

    func save() {
        do {
            let data = try JSONEncoder().encode(metadata)
            try data.write(to: FileManager.promptMetaDataURL, options: [.atomicWrite, .completeFileProtection])
        } catch {
            print("Failed to save prompt metadata: \(error)")
        }
    }

    func update(_ item: PromptMetaData) {
        if let index = metadata.firstIndex(where: { $0.id == item.id }) {
            metadata[index] = item
        } else {
            metadata.append(item)
        }
        save()
    }

    func remove(_ item: PromptMetaData) {
        metadata.removeAll { $0.id == item.id }
        save()
    }

    func getMeta(for promptText: String) -> PromptMetaData? {
        return metadata.first { $0.promptText == promptText }
    }
}
