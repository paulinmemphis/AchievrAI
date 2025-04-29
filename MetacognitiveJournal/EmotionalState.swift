//
//  EmotionalState.swift
//  MetacognitiveJournal
//
//  Created by Paul Thomas on 4/13/25.
//


import SwiftUI

enum EmotionalState: String, Codable, CaseIterable {
    case overwhelmed = "Overwhelmed"
    case frustrated = "Frustrated"
    case confused = "Confused"
    case neutral = "Neutral"
    case curious = "Curious"
    case satisfied = "Satisfied"
    case confident = "Confident"
    
    var emoji: String {
        switch self {
        case .confident: return "😎"
        case .confused: return "🤔"
        case .frustrated: return "😤"
        case .satisfied: return "😌"
        case .neutral: return "😐"
        case .curious: return "🧐"
        case .overwhelmed: return "😩"
        }
    }
    
    var color: Color {
        switch self {
        case .overwhelmed: return Color(red: 0.85, green: 0.45, blue: 0.8)  // Softer pink
        case .frustrated: return Color(red: 0.85, green: 0.3, blue: 0.3)   // Softer red
        case .confused: return Color(red: 0.95, green: 0.65, blue: 0.3)   // Softer orange
        case .neutral: return Color(red: 0.6, green: 0.6, blue: 0.6)      // Medium gray
        case .curious: return Color(red: 0.5, green: 0.4, blue: 0.8)      // Softer purple
        case .satisfied: return Color(red: 0.35, green: 0.7, blue: 0.45)  // Softer green
        case .confident: return Color(red: 0.25, green: 0.55, blue: 0.85) // Softer blue
        }
    }
}