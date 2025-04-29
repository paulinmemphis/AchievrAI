//
//  SentimentMeterView.swift
//  MetacognitiveJournal
//
//  Created by Paul Thomas on 4/13/25.
//


import SwiftUI

struct SentimentMeterView: View {
    let value: Double   // Expected to be between 0.0 and 1.0
    let label: String
    let color: Color

    var body: some View {
        VStack {
            ZStack(alignment: .bottom) {
                Capsule()
                    .frame(width: 20, height: 100)
                    .foregroundColor(color.opacity(0.2))

                Capsule()
                    .frame(width: 20, height: CGFloat(value) * 100)
                    .foregroundColor(color)
                    .animation(.easeInOut(duration: 0.8), value: value)
            }

            Text(label)
                .font(.caption)
                .multilineTextAlignment(.center)
                .frame(width: 60)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label) sentiment level: \(Int(value * 100)) percent")
    }
}