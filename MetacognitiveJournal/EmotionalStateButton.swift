//
//  EmotionalStateButton.swift
//  MetacognitiveJournal
//
//  Created by Paul Thomas on 4/13/25.
//

import SwiftUI
import NaturalLanguage

struct EmotionalStateButton: View {
    let state: EmotionalState
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        VStack {
            Text(state.emoji)
                .font(.system(size: 30))
                .accessibilityHidden(true)
            
            Text(state.rawValue)
                .font(.caption)
                .foregroundColor(isSelected ? .blue : .primary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: AppConstants.cornerRadius)
                .stroke(isSelected ? Color.blue : Color.gray.opacity(0.3), lineWidth: isSelected ? 2 : 1)
                .background(isSelected ? Color.blue.opacity(0.1) : Color.clear)
                .cornerRadius(AppConstants.cornerRadius)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(state.rawValue) feeling")
        .accessibilityHint("Double tap to select this feeling")
        .accessibilityAddTraits(isSelected ? .isSelected : []
        )
        .onTapGesture {
            action()
        }
    }
}
