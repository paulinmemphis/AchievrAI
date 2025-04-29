
//
//  NLPOperations.swift
//  MetacognitiveJournal
//
//  Created by Paul Thomas on 4/13/25.
//

import Foundation
import NaturalLanguage

// Using consolidated model definitions from MCJModels.swift

class NLPOperations {
    static let shared = NLPOperations()
    
    private let tagger = NLTagger(tagSchemes: [.lexicalClass, .lemma, .sentimentScore])
    private let sentimentTagger = NLTagger(tagSchemes: [.sentimentScore])
    private let nlpQueue = DispatchQueue(label: "com.metacognitivejournal.nlpQueue", qos: .userInitiated)

    func extractKeywords(from text: String, maxWords: Int, completion: @escaping ([String]) -> Void) {
        nlpQueue.async {
            guard !text.isEmpty else {
                DispatchQueue.main.async { completion([]) }
                return
            }

            self.tagger.string = text
            let options: NLTagger.Options = [.omitPunctuation, .omitWhitespace, .omitOther]
            let desiredTags: Set<NLTag> = [.noun, .verb, .adjective]
            var wordCounts: [String: Int] = [:]

            self.tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .lexicalClass, options: options) { tag, tokenRange in
                if let tag = tag, desiredTags.contains(tag) {
                    let word = String(text[tokenRange])
                    if word.count > 2 {
                        wordCounts[word, default: 0] += 1
                    }
                }
                return true
            }

            let sorted = wordCounts.sorted { $0.value > $1.value }
                .prefix(maxWords)
                .map { $0.key }

            DispatchQueue.main.async {
                completion(sorted)
            }
        }
    }

    func analyzeSentiment(in responses: [String], completion: @escaping (SentimentScore) -> Void) {
        nlpQueue.async {
            var positive = 0.0
            var negative = 0.0
            var neutral = 0.0
            let total = max(1, responses.count)

            for response in responses {
                self.sentimentTagger.string = response
                let (tag, _) = self.sentimentTagger.tag(at: response.startIndex, unit: .paragraph, scheme: .sentimentScore)
                if let scoreString = tag?.rawValue, let score = Double(scoreString) {
                    if score > 0.1 {
                        positive += 1
                    } else if score < -0.1 {
                        negative += 1
                    } else {
                        neutral += 1
                    }
                } else {
                    neutral += 1
                }
            }

            let result = SentimentScore(
                positive: positive / Double(total),
                negative: negative / Double(total),
                neutral: neutral / Double(total)
            )

            DispatchQueue.main.async {
                completion(result)
            }
        }
    }

    func identifyLearningPatterns(from responses: [String], completion: @escaping ([LearningStylePattern: Int]) -> Void) {
        nlpQueue.async {
            var patternCounts: [LearningStylePattern: Int] = [:]
            for pattern in LearningStylePattern.allCases {
                let count = responses.reduce(0) { total, response in
                    total + pattern.keywords.reduce(0) { $0 + (response.lowercased().contains($1) ? 1 : 0) }
                }
                if count > 0 {
                    patternCounts[pattern] = count
                }
            }

            DispatchQueue.main.async {
                completion(patternCounts)
            }
        }
    }

    func extractTopicFromResponse(_ response: String, completion: @escaping (String?) -> Void) {
        nlpQueue.async {
            let tagger = NLTagger(tagSchemes: [.lexicalClass])
            tagger.string = response
            let options: NLTagger.Options = [.omitPunctuation, .omitWhitespace, .joinNames]

            var nouns: [String] = []

            tagger.enumerateTags(in: response.startIndex..<response.endIndex, unit: .word, scheme: .lexicalClass, options: options) { tag, tokenRange in
                if let tag = tag, tag == .noun {
                    let word = String(response[tokenRange])
                    if word.count > 2 {
                        nouns.append(word)
                    }
                }
                return true
            }

            let topic = nouns.first
            DispatchQueue.main.async {
                completion(topic)
            }
        }
    }

    func extractCommonStrategies(from responses: [String], completion: @escaping ([String]) -> Void) {
        nlpQueue.async {
            let strategyKeywords: [String: String] = [
                "break down": "Breaking problems into smaller parts",
                "example": "Starting with concrete examples",
                "diagram": "Creating visual diagrams or sketches",
                "discuss": "Discussing concepts with peers",
                "practice": "Practicing with similar problems",
                "explain": "Teaching or explaining to others",
                "review": "Reviewing previous material",
                "real-world": "Finding real-world applications",
                "note": "Taking organized notes",
                "visualize": "Visualizing concepts",
                "connect": "Connecting to prior knowledge",
                "question": "Asking clarifying questions",
                "test": "Self-testing knowledge",
                "summarize": "Summarizing information"
            ]

            var foundStrategies: [String: Int] = [:]

            for response in responses {
                let lowerResponse = response.lowercased()
                for (keyword, strategy) in strategyKeywords {
                    if lowerResponse.contains(keyword) {
                        foundStrategies[strategy, default: 0] += 1
                    }
                }
            }

            DispatchQueue.main.async {
                completion(foundStrategies.keys.sorted())
            }
        }
    }
}
