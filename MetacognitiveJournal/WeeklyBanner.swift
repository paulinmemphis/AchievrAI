//
//  WeeklyBanner.swift
//  MetacognitiveJournal
//
//  Created by Paul Thomas on 4/19/25.
//


import SwiftUI

struct WeeklyBanner: View {
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "lightbulb.fill")
                .foregroundColor(.yellow)
            Text("Weekly insights ready!")
                .font(.headline)
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(12)
        .shadow(radius: 6)
        .padding(.horizontal)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Weekly insights ready. Tap insights tab to view.")
    }
}