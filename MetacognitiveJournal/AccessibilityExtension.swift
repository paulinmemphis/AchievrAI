//
//  AccessibilityExtension.swift
//  MetacognitiveJournal
//
//  Created by Paul Thomas on 4/13/25.
//

import SwiftUI

extension View {
    func improvedAccessibility(
        label: String? = nil,
        hint: String? = nil,
        traits: AccessibilityTraits = [],
        hidden: Bool = false,
        combineChildren: Bool = false
    ) -> some View {
        self
            .accessibilityElement(children: combineChildren ? .combine : .contain)
            .accessibilityLabel(label ?? "")
            .accessibilityHint(hint ?? "")
            .accessibilityAddTraits(traits)
            .accessibilityHidden(hidden)
    }
}
