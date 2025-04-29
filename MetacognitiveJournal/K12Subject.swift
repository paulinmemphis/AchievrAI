//
//  K12Subject.swift
//  MetacognitiveJournal
//
//  Created by Paul Thomas on 4/13/25.
//


import SwiftUI

enum K12Subject: String, Codable, CaseIterable {
    case math = "Mathematics"
    case science = "Science"
    case english = "English Language Arts"
    case history = "History"
    case socialStudies = "Social Studies"
    case computerScience = "Computer Science"
    case art = "Art"
    case music = "Music"
    case physicalEducation = "Physical Education"
    case foreignLanguage = "Foreign Language"
    case biology = "Biology"
    case chemistry = "Chemistry"
    case physics = "Physics"
    case geography = "Geography"
    case economics = "Economics"
    case writing = "Writing"
    case reading = "Reading"
    case other = "Other"
    
    var icon: String {
        switch self {
        case .math: return "function"
        case .science: return "atom"
        case .english: return "book"
        case .history: return "scroll"
        case .socialStudies: return "person.3"
        case .computerScience: return "desktopcomputer"
        case .art: return "paintpalette"
        case .music: return "music.note"
        case .physicalEducation: return "figure.run"
        case .foreignLanguage: return "globe"
        case .biology: return "leaf"
        case .chemistry: return "flask"
        case .physics: return "gyroscope"
        case .geography: return "map"
        case .economics: return "chart.bar"
        case .writing: return "pencil"
        case .reading: return "book.closed"
        case .other: return "questionmark.square"
        }
    }
}