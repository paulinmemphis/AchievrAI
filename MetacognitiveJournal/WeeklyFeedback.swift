//
//  WeeklyFeedback.swift
//  MetacognitiveJournal
//
//  Created by Paul Thomas on 4/19/25.
//

import Foundation

struct WeeklyFeedback: Identifiable {
    var id = UUID()
    var weekStartDate: Date
    var subject: K12Subject
    var summary: String
    var dominantEmotion: EmotionalState
    var highlights: [String]
}

extension Date {
    func startOfWeek() -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)
        return calendar.date(from: components) ?? self
    }
}
