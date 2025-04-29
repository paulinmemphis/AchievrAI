//
//  EmptyInsightsView.swift
//  MetacognitiveJournal
//
//  Created by Paul Thomas on 4/13/25.
//


import SwiftUI

struct EmptyInsightsView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 60))
                .foregroundColor(.blue)
                .accessibilityHidden(true)
            
            Text("Add more journal entries")
                .font(.headline)
            
            Text("You need at least \(AppConstants.minimumEntriesForAnalysis) journal entries to see personalized learning insights.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }
}